# HamSekans (هم‌سکانس) - Cinematic Social Network

A comprehensive movie tracking and reviewing mobile application developed with a focus on strict Software Engineering principles and Clean Architecture. HamSekans serves as a localized social platform for movie enthusiasts to catalog, share, and discuss their cinematic experiences.

---

## **Key Features**

* **Social & Collaborative:** Create and share collaborative watchlists with other users.
* **Real-time Synchronization:** Powered by Supabase Realtime for instant updates on social feeds, reviews, and interactions.
* **Optimized Performance:** Achieves sub-3ms data fetching response times using robust in-memory caching via Riverpod and Dio network interceptors.
* **Secure Cloud Backend:** Operates on a cloud-native data layer using Supabase, with strict Row-Level Security (RLS) policies guaranteeing user data privacy.
* **RTL & BiDi Support:** Fully optimized user interface designed specifically for Persian language and Bidirectional text layouts using Material Design.
* **Optimistic UI:** Implements optimistic UI updates to provide a seamless, lag-free experience even under unstable network conditions.

---

## **Tech Stack & Architecture**

* **Framework:** Flutter (Dart)
* **Architecture:** Clean Architecture (Separation of Presentation, Domain, and Data/Repository layers)
* **State Management:** Riverpod (AutoDispose, Asynchronous Providers)
* **Networking & Caching:** Dio (Interceptor Pattern), local memory/SQLite caching
* **Backend (BaaS):** Supabase (PostgreSQL, RLS, Authentication)
* **Metadata Provider:** TMDB (The Movie Database) API

---

## **Getting Started**

1. **Clone the repository:** 
   ```bash
   git clone [https://github.com/YourUsername/HamSekans.git](https://github.com/YourUsername/HamSekans.git)


3. **Set up environment variables:** Add your Supabase URL, Supabase Anon Key, and TMDB API Key to the project configuration.
4. **Run the application:**
   ```bash
   flutter run

## App Introduction & Preview
You can find the full visual preview and a complete introduction to the application here:

https://drive.google.com/file/d/1zEwt2dLkTNmFCRUfcUY3HsLNLde5xFhi/view?usp=sharing
