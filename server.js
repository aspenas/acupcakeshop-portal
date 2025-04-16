import express from 'express';
import mongoose from 'mongoose';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import dotenv from 'dotenv';
import session from 'express-session';
import passport from 'passport';
import { Strategy as GoogleStrategy } from 'passport-google-oauth20';
import { Strategy as JwtStrategy, ExtractJwt } from 'passport-jwt';
import jwt from 'jsonwebtoken';
import User from './models/User.js';
import obsidianRoutes from './routes/obsidian.js';
import fs from 'fs';

// Load environment variables
dotenv.config();

// Get directory name for ES Module
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 3000;

// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI, {
  dbName: process.env.MONGO_DB_NAME,
  useNewUrlParser: true,
  useUnifiedTopology: true
})
.then(() => console.log('Connected to MongoDB'))
.catch(err => console.error('MongoDB connection error:', err));

// Configure session
app.use(session({
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: { secure: process.env.NODE_ENV === 'production' }
}));

// Initialize Passport
app.use(passport.initialize());
app.use(passport.session());

// Configure Google Strategy
passport.use(new GoogleStrategy({
  clientID: process.env.GOOGLE_CLIENT_ID,
  clientSecret: process.env.GOOGLE_CLIENT_SECRET,
  callbackURL: process.env.GOOGLE_CALLBACK_URL
}, async (accessToken, refreshToken, profile, done) => {
  try {
    // Only allow users from the specified workspace domain
    const email = profile.emails[0].value;
    const domain = email.split('@')[1];
    
    if (domain !== process.env.GOOGLE_WORKSPACE_DOMAIN) {
      return done(null, false, { message: 'Invalid domain' });
    }
    
    // Check if user exists
    let user = await User.findOne({ googleId: profile.id });
    
    if (!user) {
      // Create new user
      user = await User.create({
        googleId: profile.id,
        email: email,
        displayName: profile.displayName,
        isAdmin: process.env.ADMIN_EMAILS?.split(',').includes(email) || false
      });
    } else {
      // Update last login
      await user.updateLastLogin();
    }
    
    return done(null, user);
  } catch (error) {
    return done(error);
  }
}));

// Serialize and deserialize user
passport.serializeUser((user, done) => {
  done(null, user.id);
});

passport.deserializeUser(async (id, done) => {
  try {
    const user = await User.findById(id);
    done(null, user);
  } catch (error) {
    done(error);
  }
});

// Configure JWT Strategy
passport.use(new JwtStrategy({
  jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
  secretOrKey: process.env.JWT_SECRET
}, async (payload, done) => {
  try {
    const user = await User.findById(payload.sub);
    if (!user) return done(null, false);
    return done(null, user);
  } catch (error) {
    return done(error, false);
  }
}));

// Enable JSON parsing
app.use(express.json());

// Auth routes
app.get('/auth/google',
  passport.authenticate('google', { scope: ['profile', 'email'] })
);

app.get('/auth/google/callback', 
  passport.authenticate('google', { failureRedirect: '/login' }),
  (req, res) => {
    // Generate JWT token
    const token = jwt.sign(
      { sub: req.user._id, email: req.user.email },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );
    
    // Redirect to frontend with token
    res.redirect(`/?token=${token}`);
  }
);

// Define middleware to check authentication
const authenticateJWT = passport.authenticate('jwt', { session: false });

// User API route
app.get('/api/user', authenticateJWT, (req, res) => {
  res.json({ user: req.user });
});

// Use Obsidian routes for content
app.use('/api/obsidian', authenticateJWT, obsidianRoutes);

// Serve root directory first (for index.html)
app.use(express.static(__dirname));

// Then fall back to other directories
if (fs.existsSync(join(__dirname, 'dist'))) {
  console.log('Serving static files from dist directory');
  app.use(express.static(join(__dirname, 'dist')));
} else {
  console.log('dist directory not found, serving from src directory');
  app.use(express.static(join(__dirname, 'src')));
}

// Root route
app.get('/', (req, res) => {
  // Check for index.html in root directory first
  if (fs.existsSync(join(__dirname, 'index.html'))) {
    res.sendFile(join(__dirname, 'index.html'));
    return;
  }
  
  // Then check dist and src directories
  if (fs.existsSync(join(__dirname, 'dist', 'index.html'))) {
    res.sendFile(join(__dirname, 'dist', 'index.html'));
    return;
  }
  
  if (fs.existsSync(join(__dirname, 'src', 'index.html'))) {
    res.sendFile(join(__dirname, 'src', 'index.html'));
    return;
  }
  
  // If no index.html found anywhere, send the embedded welcome page
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>A Cup Cake Shop Portal</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { font-family: Arial, sans-serif; margin: 0; padding: 20px; line-height: 1.6; }
          .container { max-width: 800px; margin: 0 auto; padding: 20px; }
          h1 { color: #333; }
          .card { border: 1px solid #ddd; border-radius: 4px; padding: 20px; margin-bottom: 20px; }
          .button { display: inline-block; background: #007bff; color: white; padding: 10px 15px; text-decoration: none; border-radius: 4px; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>Welcome to A Cup Cake Shop Portal</h1>
          <div class="card">
            <h2>Site under construction</h2>
            <p>Our portal is currently being set up. Please check back soon!</p>
            <p>You can try to:</p>
            <ul>
              <li><a href="/auth/google">Sign in with Google</a></li>
              <li><a href="/api/obsidian/dir/">Browse Obsidian Vault Files (requires authentication)</a></li>
            </ul>
          </div>
        </div>
      </body>
    </html>
  `);
});

// Catch-all route
app.get('*', (req, res) => {
  // Try to find the path or redirect to home
  const rootPath = join(__dirname, req.path);
  const distPath = join(__dirname, 'dist', req.path);
  const srcPath = join(__dirname, 'src', req.path);
  
  if (fs.existsSync(rootPath)) {
    res.sendFile(rootPath);
  } else if (fs.existsSync(distPath)) {
    res.sendFile(distPath);
  } else if (fs.existsSync(srcPath)) {
    res.sendFile(srcPath);
  } else {
    res.redirect('/');
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Root directory: ${__dirname}`);
  console.log(`index.html exists in root: ${fs.existsSync(join(__dirname, 'index.html'))}`);
}); 