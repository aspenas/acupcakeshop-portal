---
title: Financial Analytics
theme: glacier
toc: true
---

# Financial Dashboard

<div class="hero">
  <h1>Financial Analytics</h1>
  <h2>Interactive visualizations for financial data analysis</h2>
</div>

## Market Performance

This visualization tracks market performance using the AAPL data that comes with Observable Framework.

```js
// Using the AAPL dataset that comes with Observable Framework
function stockChart({width} = {}) {
  return Plot.plot({
    title: "Apple Stock Price",
    width,
    height: 300,
    y: {grid: true, label: "Price ($)"},
    marks: [
      Plot.line(aapl, {x: "Date", y: "Close", tip: true}),
      Plot.ruleY([0])
    ]
  });
}
```

<div class="grid grid-cols-1">
  <div class="card">
    ${resize((width) => stockChart({width}))}
  </div>
</div>

## Financial Timeline

Important financial events visualization using the built-in Timeline component.

```js
import {timeline} from "./components/timeline.js";

// Using the same timeline component from example-report.md
const events = FileAttachment("data/financial-events.json").json();

// Using the exact same pattern as the example-report.md
timeline(events, {height: 300})
```

## Asset Allocation

Using the Dashboard example pattern to show asset allocation.

```js
// Sample portfolio data
const portfolio = [
  {asset: "US Stocks", allocation: 40},
  {asset: "International Stocks", allocation: 20},
  {asset: "Bonds", allocation: 25},
  {asset: "Real Estate", allocation: 10},
  {asset: "Cash", allocation: 5}
];

// Create a chart function similar to example-dashboard.md's vehicleChart
function allocationChart({width} = {}) {
  return Plot.plot({
    title: "Portfolio Allocation",
    width,
    height: 300,
    marginLeft: 120,
    x: {grid: true, label: "Allocation (%)"},
    y: {label: null},
    marks: [
      Plot.barX(portfolio, {
        x: "allocation",
        y: "asset",
        fill: "asset",
        sort: {y: "-x"},
        tip: true
      })
    ]
  });
}
```

<div class="grid grid-cols-1">
  <div class="card">
    ${resize((width) => allocationChart({width}))}
  </div>
</div>

## Key Financial Metrics

Financial metrics cards based on the dashboard example for showing key numbers.

<div class="grid grid-cols-4">
  <div class="card">
    <h2>Total Portfolio</h2>
    <span class="big">$500,000</span>
  </div>
  <div class="card">
    <h2>YTD Return</h2>
    <span class="big">12.4%</span>
  </div>
  <div class="card">
    <h2>Dividend Yield</h2>
    <span class="big">3.2%</span>
  </div>
  <div class="card">
    <h2>Risk Score</h2>
    <span class="big">65</span>
  </div>
</div>

## Market Sectors

Using the dashboard example pattern to display financial data across market categories.

```js
// Sample market sectors data
const sectors = [
  {sector: "Technology", return: 25},
  {sector: "Healthcare", return: 12},
  {sector: "Financials", return: 8},
  {sector: "Consumer", return: 15},
  {sector: "Industrials", return: 10},
  {sector: "Energy", return: -5},
  {sector: "Materials", return: 3},
  {sector: "Utilities", return: -2},
  {sector: "Real Estate", return: -8}
];

// Create a function similar to example-dashboard.md's vehicleChart
function sectorChart({width} = {}) {
  return Plot.plot({
    title: "Market Sectors Performance",
    width,
    height: 300,
    marginLeft: 120,
    x: {grid: true, label: "YTD Return (%)"},
    y: {label: null},
    marks: [
      Plot.barX(sectors, {
        x: "return",
        y: "sector",
        fill: d => d.return > 0 ? "steelblue" : "tomato",
        sort: {y: "-x"},
        tip: true
      })
    ]
  });
}
```

<div class="grid grid-cols-1">
  <div class="card">
    ${resize((width) => sectorChart({width}))}
  </div>
</div>

## Retirement Scenarios

This bar chart compares different retirement scenarios.

```js
// Sample retirement scenarios
const scenarios = [
  {scenario: "Conservative", final_amount: 975000, risk: 3, return: 5},
  {scenario: "Moderate", final_amount: 1520000, risk: 5, return: 7},
  {scenario: "Aggressive", final_amount: 2350000, risk: 8, return: 9},
  {scenario: "Ultra-Aggressive", final_amount: 3680000, risk: 10, return: 11}
];

// Create a function similar to example-dashboard.md's vehicleChart
function scenarioChart({width} = {}) {
  return Plot.plot({
    title: "Retirement Scenarios",
    width,
    height: 300,
    marginLeft: 120,
    x: {grid: true, label: "Final Amount ($)"},
    y: {label: null},
    marks: [
      Plot.barX(scenarios, {
        x: "final_amount",
        y: "scenario",
        fill: "scenario",
        sort: {y: "-x"},
        tip: true
      })
    ]
  });
}
```

<div class="grid grid-cols-1">
  <div class="card">
    ${resize((width) => scenarioChart({width}))}
  </div>
</div>

## Risk-Return Analysis

This chart compares risk, return, and success probability for different retirement scenarios.

```js
// Create a function similar to penguin scatter plot
function riskReturnChart({width} = {}) {
  return Plot.plot({
    title: "Risk vs. Return Analysis",
    width,
    height: 500,
    grid: true,
    x: {label: "Risk Level"},
    y: {label: "Expected Return (%)"},
    marks: [
      Plot.dot(scenarios, {
        x: "risk",
        y: "return",
        fill: "scenario",
        tip: true
      }),
      Plot.text(scenarios, {
        x: "risk",
        y: "return",
        text: "scenario",
        dy: -15
      })
    ]
  });
}
```

<div class="grid grid-cols-1">
  <div class="card">
    ${resize((width) => riskReturnChart({width}))}
  </div>
</div>

## Integration with Finance Projects

<div class="grid grid-cols-2 gap-6 my-8">
  <div class="card">
    <div class="card-body">
      <h3 class="card-title">Finance AI Project Integration</h3>
      <p class="mb-4">Connect your AI-powered financial analysis tools with Observable Framework to create comprehensive dashboards.</p>
      
      <h4 class="font-bold mb-2">Integration Options:</h4>
      <ul class="list-disc pl-5 space-y-1">
        <li>Import transaction data from your finance_ai_project</li>
        <li>Visualize AI-generated predictions and insights</li>
        <li>Create interactive dashboards for financial planning</li>
        <li>Export visualizations for reports and presentations</li>
      </ul>
    </div>
  </div>
  
  <div class="card">
    <div class="card-body">
      <h3 class="card-title">Finance Simulation Integration</h3>
      <p class="mb-4">Enhance your financial simulations with interactive visualizations to explore different scenarios.</p>
      
      <h4 class="font-bold mb-2">Integration Options:</h4>
      <ul class="list-disc pl-5 space-y-1">
        <li>Visualize Monte Carlo simulation results</li>
        <li>Create interactive retirement calculators</li>
        <li>Build scenario comparison tools</li>
        <li>Generate financial planning dashboards</li>
      </ul>
    </div>
  </div>
</div>

## Obsidian Integration

Observable Framework visualizations can be seamlessly integrated with your Obsidian vault for comprehensive financial knowledge management.

<div class="card my-6">
  <div class="card-body">
    <h3 class="card-title">Obsidian Knowledge Management</h3>
    
    <div class="grid grid-cols-2 gap-4 mt-4">
      <div>
        <h4 class="font-bold mb-2">Integration Benefits</h4>
        <ul class="list-disc pl-5 space-y-1">
          <li>Embed interactive financial visualizations</li>
          <li>Link financial analysis to your knowledge base</li>
          <li>Create visual representations of financial concepts</li>
          <li>Build a comprehensive financial planning system</li>
          <li>Track portfolio performance over time</li>
        </ul>
      </div>
      <div>
        <h4 class="font-bold mb-2">Implementation Methods</h4>
        <ol class="list-decimal pl-5 space-y-1">
          <li>Export static SVG/PNG visualizations</li>
          <li>Create HTML snippets for interactive elements</li>
          <li>Use iframe embedding for complex visualizations</li>
          <li>Generate Markdown files with embedded charts</li>
          <li>Create custom Obsidian plugins for deeper integration</li>
        </ol>
      </div>
    </div>
  </div>
</div>

## Conclusion

Observable Framework provides powerful tools for financial data visualization that can enhance your existing projects. With its rich library of visualization capabilities, you can:

1. Create beautiful, interactive financial dashboards
2. Visualize investment performance and projections
3. Build portfolio analysis tools
4. Connect to your existing finance projects
5. Integrate with your knowledge management system

Explore the [official Observable Framework documentation](https://observablehq.com/framework/documentation) to learn more about building sophisticated financial visualizations.