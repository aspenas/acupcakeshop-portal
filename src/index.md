---
toc: false
theme: glacier
---

<div class="hero">
  <h1>A Cup Cake Shop</h1>
  <h2>Interactive visualizations for financial data analysis</h2>
</div>

## Financial Dashboard

<!-- Define visualization functions -->

```js
// Stock Chart function
function stockChart(data, {width} = {}) {
  return Plot.plot({
    title: "Market Performance",
    width,
    height: 300,
    y: {grid: true, label: "Price ($)"},
    marks: [
      Plot.line(data, {x: "trade_date", y: "price", tip: true, stroke: "steelblue", filter: d => d.symbol === "AAPL"}),
      Plot.ruleY([0])
    ]
  });
}

// Portfolio Allocation function
function portfolioAllocation(data, {width} = {}) {
  // Get the latest data for each asset type
  const latestData = d3.rollup(
    data,
    v => d3.max(v, d => new Date(d.date)), // Find latest date
    d => d.asset // Group by asset
  );
  
  // Create allocation dataset
  const allocation = Array.from(d3.rollup(
    data,
    v => {
      const assetData = v.filter(d => d.date === latestData.get(v[0].asset).toISOString().slice(0, 10));
      return assetData.length > 0 ? assetData[0].value : 0;
    },
    d => d.asset
  ), ([asset, value]) => ({asset, value}));
  
  // Calculate percentages
  const total = d3.sum(allocation, d => d.value);
  const percentages = allocation.map(d => ({
    asset: d.asset,
    allocation: Math.round((d.value / total) * 100)
  }));
  
  // Add a Cash category if not present
  if (!percentages.find(d => d.asset === "Cash")) {
    percentages.push({asset: "Cash", allocation: 5});
  }
  
  return Plot.plot({
    title: "Portfolio Allocation",
    width,
    height: 300,
    marginLeft: 120,
    x: {grid: true, label: "Allocation (%)"},
    y: {label: null},
    marks: [
      Plot.barX(percentages, {
        x: "allocation",
        y: "asset",
        fill: "asset",
        sort: {y: "-x"},
        tip: true
      })
    ]
  });
}

// Market Sectors function
function marketSectors({width} = {}) {
  return Plot.plot({
    title: "Market Sectors",
    width,
    height: 300,
    marginLeft: 120,
    x: {grid: true, label: "YTD Return (%)"},
    y: {label: null},
    marks: [
      Plot.barX([
        {sector: "Technology", return: 25},
        {sector: "Healthcare", return: 12},
        {sector: "Financials", return: 8},
        {sector: "Consumer", return: 15},
        {sector: "Industrials", return: 10},
        {sector: "Energy", return: -5},
        {sector: "Materials", return: 3},
        {sector: "Utilities", return: -2},
        {sector: "Real Estate", return: -8}
      ], {
        x: "return",
        y: "sector",
        fill: d => d.return > 0 ? "steelblue" : "tomato",
        sort: {y: "-x"},
        tip: true
      })
    ]
  });
}

// Economic Indicators function
function economicIndicators(data, {width} = {}) {
  return Plot.plot({
    title: "Economic Indicators",
    width,
    height: 300,
    y: {
      grid: true, 
      label: "Value", 
      percent: true
    },
    color: {legend: true},
    marks: [
      Plot.line(data, {
        x: "Date", 
        y: "Unemployment", 
        stroke: "Metric", 
        tip: true
      }),
      Plot.line(data, {
        x: "Date", 
        y: "Inflation", 
        stroke: "Metric", 
        tip: true
      })
    ]
  });
}

// Retirement Scenarios function
function retirementScenarios({width} = {}) {
  return Plot.plot({
    title: "Retirement Scenarios",
    width,
    height: 300,
    marginLeft: 120,
    x: {grid: true, label: "Final Amount ($M)"},
    y: {label: null},
    marks: [
      Plot.barX([
        {scenario: "Conservative", final_amount: 0.98},
        {scenario: "Moderate", final_amount: 1.52},
        {scenario: "Aggressive", final_amount: 2.35},
        {scenario: "Ultra-Aggressive", final_amount: 3.68}
      ], {
        x: "final_amount",
        y: "scenario",
        fill: "scenario",
        sort: {y: "-x"},
        tip: true
      })
    ]
  });
}

// Risk vs Return function
function riskReturn({width} = {}) {
  return Plot.plot({
    title: "Risk vs. Return",
    width,
    height: 300,
    grid: true,
    x: {label: "Risk Level", domain: [0, 12]},
    y: {label: "Expected Return (%)", domain: [0, 12]},
    marks: [
      Plot.dot([
        {scenario: "Conservative", risk: 3, return: 5},
        {scenario: "Moderate", risk: 5, return: 7},
        {scenario: "Aggressive", risk: 8, return: 9},
        {scenario: "Ultra-Aggressive", risk: 10, return: 11}
      ], {
        x: "risk",
        y: "return",
        r: 10,
        fill: "scenario",
        tip: true
      })
    ]
  });
}

// Retirement Income function
function retirementIncome({width} = {}) {
  return Plot.plot({
    title: "Retirement Income",
    width,
    height: 300,
    marginLeft: 120,
    x: {grid: true, label: "Monthly Income ($)"},
    y: {label: null},
    marks: [
      Plot.barX([
        {scenario: "Conservative", income: 3900},
        {scenario: "Moderate", income: 6080},
        {scenario: "Aggressive", income: 9400},
        {scenario: "Ultra-Aggressive", income: 14720}
      ], {
        x: "income",
        y: "scenario",
        fill: "scenario",
        sort: {y: "-x"},
        tip: true
      })
    ]
  });
}

// AAPL Trades Over Time function
function aaplTradesOverTime(data, {width} = {}) {
  // Filter for only AAPL buy/sell transactions and sort by date
  const aaplTrades = data
    .filter(d => d.symbol === "AAPL")
    .sort((a, b) => new Date(a.trade_date) - new Date(b.trade_date));
  
  return Plot.plot({
    title: "AAPL Trading Activity",
    width,
    height: 300,
    y: {grid: true, label: "Price ($)"},
    color: {
      legend: true,
      domain: ["buy", "sell"],
      range: ["steelblue", "tomato"]
    },
    marks: [
      Plot.line(aaplTrades, {
        x: "trade_date", 
        y: "price",
        stroke: "steelblue",
        strokeWidth: 1.5
      }),
      Plot.dot(aaplTrades, {
        x: "trade_date", 
        y: "price",
        fill: d => d.type,
        r: 5,
        tip: true
      })
    ]
  });
}
```

<div class="grid grid-cols-2 gap-4">
  <!-- Stock Chart -->
  <div class="card">
    <h3 class="card-title">Market Performance</h3>
    <p>Stock price visualization using AAPL trades data.</p>
    ${resize((width) => stockChart(trades, {width}))}
  </div>

  <!-- Asset Allocation -->
  <div class="card">
    <h3 class="card-title">Portfolio Allocation</h3>
    <p>Breakdown of investment categories.</p>
    ${resize((width) => portfolioAllocation(portfolioData, {width}))}
  </div>

  <!-- Market Sectors -->
  <div class="card">
    <h3 class="card-title">Market Sectors</h3>
    <p>Year-to-date performance by market sector.</p>
    ${resize((width) => marketSectors({width}))}
  </div>

  <!-- Economic Indicators -->
  <div class="card">
    <h3 class="card-title">Economic Indicators</h3>
    <p>Unemployment and inflation rates over time.</p>
    ${resize((width) => economicIndicators(economics, {width}))}
  </div>

  <!-- Retirement Scenarios -->
  <div class="card">
    <h3 class="card-title">Retirement Scenarios</h3>
    <p>Comparison of different investment strategies.</p>
    ${resize((width) => retirementScenarios({width}))}
  </div>

  <!-- Risk Return Analysis -->
  <div class="card">
    <h3 class="card-title">Risk vs. Return</h3>
    <p>Relationship between risk and expected return.</p>
    ${resize((width) => riskReturn({width}))}
  </div>

  <!-- Monthly Income -->
  <div class="card">
    <h3 class="card-title">Retirement Income</h3>
    <p>Expected monthly income by investment strategy.</p>
    ${resize((width) => retirementIncome({width}))}
  </div>

  <!-- AAPL Trading Activity -->
  <div class="card">
    <h3 class="card-title">AAPL Trading Activity</h3>
    <p>Buy/sell transactions of Apple stock over time.</p>
    ${resize((width) => aaplTradesOverTime(trades, {width}))}
  </div>
</div>

## Key Financial Metrics

<div class="grid grid-cols-4 gap-4 my-4">
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

## Historical Financial Events

<div class="grid grid-cols-1 gap-4">
  <div class="card">
    <h3 class="card-title">Key Market Events</h3>
    <p>Timeline of significant financial events.</p>
    ${timeline(financialEvents, {height: 300})}
  </div>
</div>

<!-- Load components and data -->

```js
import {timeline} from "./components/timeline.js";

// Load data from local files
const trades = FileAttachment("data/trades.csv").csv({typed: true});
const portfolioData = FileAttachment("data/portfolio-data.json").json();
const financialEvents = FileAttachment("data/financial-events.json").json();

// Economic indicators data
const economics = [
  { Date: new Date("2015-01-01"), Unemployment: 0.057, Inflation: 0.008, Metric: "Unemployment" },
  { Date: new Date("2016-01-01"), Unemployment: 0.049, Inflation: 0.012, Metric: "Unemployment" },
  { Date: new Date("2017-01-01"), Unemployment: 0.044, Inflation: 0.021, Metric: "Unemployment" },
  { Date: new Date("2018-01-01"), Unemployment: 0.040, Inflation: 0.024, Metric: "Unemployment" },
  { Date: new Date("2019-01-01"), Unemployment: 0.037, Inflation: 0.018, Metric: "Unemployment" },
  { Date: new Date("2020-01-01"), Unemployment: 0.080, Inflation: 0.012, Metric: "Unemployment" },
  { Date: new Date("2021-01-01"), Unemployment: 0.062, Inflation: 0.047, Metric: "Unemployment" },
  { Date: new Date("2022-01-01"), Unemployment: 0.037, Inflation: 0.080, Metric: "Unemployment" },
  { Date: new Date("2023-01-01"), Unemployment: 0.035, Inflation: 0.041, Metric: "Unemployment" },
  { Date: new Date("2015-01-01"), Unemployment: 0.057, Inflation: 0.008, Metric: "Inflation" },
  { Date: new Date("2016-01-01"), Unemployment: 0.049, Inflation: 0.012, Metric: "Inflation" },
  { Date: new Date("2017-01-01"), Unemployment: 0.044, Inflation: 0.021, Metric: "Inflation" },
  { Date: new Date("2018-01-01"), Unemployment: 0.040, Inflation: 0.024, Metric: "Inflation" },
  { Date: new Date("2019-01-01"), Unemployment: 0.037, Inflation: 0.018, Metric: "Inflation" },
  { Date: new Date("2020-01-01"), Unemployment: 0.080, Inflation: 0.012, Metric: "Inflation" },
  { Date: new Date("2021-01-01"), Unemployment: 0.062, Inflation: 0.047, Metric: "Inflation" },
  { Date: new Date("2022-01-01"), Unemployment: 0.037, Inflation: 0.080, Metric: "Inflation" },
  { Date: new Date("2023-01-01"), Unemployment: 0.035, Inflation: 0.041, Metric: "Inflation" }
];
```
```