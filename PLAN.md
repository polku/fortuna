# Initial Plan for Flutter Investment Tracker

This roadmap outlines the steps required to build a mobile app that tracks investments entirely on-device using Flutter.

1. **Project Setup**
   - Install Flutter dependencies.
   - Initialize the Flutter project and configure local SQLite database support (e.g., using `sqflite`).

2. **Data Model**
   - Design SQLite tables: `operations`, `positions`, and `history`.
   - Define fields: ticker, buy/sell date, quantity, value, etc.
   - Provide migration scripts if needed.

3. **User Interface**
   - Create forms for adding buy/sell operations.
   - Build a dashboard showing portfolio value, latent gains, and position details.
   - Provide a history screen to review completed trades.

4. **Data Retrieval**
 - Integrate a free API (e.g., AlphaVantage or other) to fetch current prices for equities and crypto assets using the asset ticker.
  - Prices are only refreshed when the user taps an update button to avoid spamming the API.
  - Store the fetched prices in a local table so the portfolio can be shown offline.

5. **Calculations**
   - Compute current portfolio value and latent gains for each position.
   - Calculate realized gains or losses when closing positions.

6. **Persistence**
   - Ensure all operations and price data are stored locally in SQLite, enabling offline access.

7. **Testing**
   - Write unit tests for database logic and calculations.
   - Perform integration tests for API interactions.

8. **Deployment**
   - Configure Android/iOS builds and create release packages.
   - Provide instructions for installation on devices.

