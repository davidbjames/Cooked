# Cooked

A meal planning and cooking timer app written in SwiftUI

Built on SwiftData, CloudKit and FoundationModels (on-device AI).

Copyright 2026 - David James

## Overview

Cooked solves a surprisingly tricky kitchen problem: when you're cooking multiple dishes with different cook times, when does each one need to go in? You build a meal plan by adding the foods you're cooking along with how long each takes, and Cooked calculates a personalised schedule telling you exactly when to start each item so they all finish simultaneously.

A built-in on-device AI ingredient databank — powered by Apple's `FoundationModels` — makes it fast to find and reuse ingredients, with results tailored to your region. Your meal plans sync across devices via CloudKit.

## Features

- **Meal plan creation** — Group multiple cooking items into a single plan.
- **Completion schedule** — Calculate a start-time schedule for every item in a plan so they all finish cooking at the same moment -- in both relative time ("in 25 min") and absolute time ("8:45 PM").
- **On-device AI food bank** — Uses Apple's on-device System Language Model to generate a personalised list of ingredients and varieties, favouring foods common in your region.
- **Cooking timers** — Start a timer from a meal plan and follow step-by-step prompts as each item's start time arrives.
- **Food variables** — Attach reusable descriptors to cooking items (e.g. "1.7 kg", "large") with autocomplete from previously used values.
- **CloudKit sync** — Meal plans, food items, and your ingredient bank sync automatically across all your devices.
- **iOS & macOS** — A single SwiftUI codebase runs natively on mobile and desktop.

## How It Works

1. **Create a meal plan** — Tap "New" and give it an optional name.
2. **Add cooking items** — Pick an ingredient from your AI-generated food bank (or enter one manually), optionally note a quantity or size, and set the cook time.
3. **View the schedule** — Cooked works out the start offset for each item relative to the longest cook time and presents a clear, ordered schedule.
4. **Start cooking** — Hit "Start" and the timer walks you through when to put each item on, ending with a final "Everything done" notification.

## Data Model

```
Profile
└── (settings: regional ingredient preference)

MealPlan ──< CookingItem >── FoodItem
                │                └── FoodGroup (staple / protein / vegetable)
                │                └── Ingredient
                │                      └── Variety
                └── FoodVariable (e.g. "1.7 kg")
```

- **`MealPlan`** — A named collection of cooking items. Total time equals the longest individual cook time.
- **`CookingItem`** — One food being cooked: links a `FoodItem` + optional `FoodVariable` + a duration.
- **`FoodItem`** — A saved food entry referencing an ingredient and optionally a specific variety.
- **`Ingredient` / `Variety`** — The AI-generated food bank. Ingredients belong to a food group; varieties are specific cuts or types (e.g. "Maris Piper potatoes").
- **`FoodVariable`** — Reusable descriptors (weight, size, etc.) shared across cooking items.

## AI Generation

The ingredient databank is built entirely on-device using [Apple's FoundationModels framework](https://developer.apple.com/documentation/foundationmodels).

Generation runs per food group (staples, proteins, vegetables) in separate model sessions to stay within context limits. Each pass provides a growing exclusion list so repeated runs add genuinely new ingredients rather than duplicates.

**Sampling strategy:**

| Pass       | Mode            | Purpose                                                          |
|------------|-----------------|------------------------------------------------------------------|
| First      | Greedy          | Deterministically captures the most common, obvious ingredients  |
| Subsequent | Nucleus (top-p) | Explores progressively more varied and regional results          |


Varieties follow the same pattern — once an ingredient exists in the bank, a separate generation step populates its specific varieties.

## Requirements

| | Minimum |
|---|---|
| iOS | 26.0 |
| macOS | 26.0 |
| Xcode | 26.0 |
| On-device model | Required for AI ingredient generation |

> **Note:** AI generation requires a device with Apple Intelligence / the on-device System Language Model available. The app gracefully falls back to manual ingredient entry if the model is unavailable.

## Project Structure

```
Cooked/
├── CookedApp.swift             # App entry point, SwiftData container setup
├── Model/                      # SwiftData models (Profile, MealPlan, CookingItem, …)
├── Generators/                 # On-device AI generation (ingredients & varieties)
│   └── Tools/                  # Generation helpers (exclusion lists, etc.)
├── Views/                      # SwiftUI views
├── Helpers/                    # Utilities (layout, generation settings, view helpers)
├── Protocols/                  # Shared protocols (TimedItem, FoodContainer, …)
└── Styles/                     # Colours and design tokens
```
