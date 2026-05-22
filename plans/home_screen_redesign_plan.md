# Home Screen Redesign Plan

## Goals
- Fix header so it remains visible when scrolling (fixed header)
- Display accurate bin inventory count (not total logged)
- Replace vague metrics in 'Scan first' section with user activity summary (level based on weekly logs) and a helpful tip
- Show actual waste reduced (estimated weight in grams) based on bin inventory
- Ensure visual consistency and clear hierarchy

## Detailed Changes

### 1. Fixed Header
- Modify the home screen to use a SliverAppBar or a fixed position header that stays at the top when scrolling.
- The header should contain the app title and the settings icon.

### 2. State Management for Display
- Replace `itemsLogged` with `widget.appState.inventory.length` for the count displayed in the header and in the 'Scan first' section.
- If we need to show total logged elsewhere, we can keep that state but not for the bin count.

### 3. Redesign 'Scan first' Section
- Remove the two metric cards (Logged and Status).
- Add a user level based on weekly logs and a helpful tip.
- The level will be descriptive and aligned with the ScrapChef theme, with 3 levels corresponding to low, medium, high activity. Example thematic levels: "Scrap Scout" (low), "Scrap Saver" (medium), "Scrap Savant" (high).
- Example: "You're a Scrap Scout! Keep scanning to unlock tips."

### 4. Improve 'Impact so far' Section
- Calculate estimated waste reduced: assume each scrap item is about 50 grams (or use an average from data if available).
- Display: "Estimated waste reduced: X grams" or "Estimated waste reduced: X kg"
- We can also show equivalent meals if we want, but the user asked for actual waste reduced.

### 5. Visual Consistency
- Update any widgets that use the old state or metrics.
- Ensure the header and tabs are styled consistently.

### 6. Layout Hierarchy
- Review the current use of SliverList, TabBarView, etc. to ensure the fixed header works and the content is scrollable appropriately.

## Notes on User Levels and K-Means Clustering
- For the user level, we will use weekly scan frequency (number of scans per week).
- With only one user currently, k-means clustering is not meaningful (it requires multiple data points to form clusters). Therefore, for now we will use rule-based thresholds to assign a level:
  * 0-2 scans/week: Scrap Scout
  * 3-5 scans/week: Scrap Saver
  * 6+ scans/week: Scrap Savant
- When we have sufficient data from multiple users, we can replace the rule-based approach with k-means clustering (k=3) to dynamically determine the levels based on actual user behavior patterns.
- The cluster assignment from k-means can then be mapped to the same thematic levels (e.g., low activity cluster -> Scrap Scout, etc.) and stored in the user's profile.
- The home screen will display the user's level from their profile (updated either by rule-based or clustering method).

## Notes
- The scanning speed depends on the API (Gemini service) and the device, so we cannot guarantee faster scanning from UI changes alone.
- We will ensure that the UI is clear and the user can understand the app by using it.