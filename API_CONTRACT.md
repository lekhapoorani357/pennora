# Pennora API Contract

## Tables (Supabase)
plans: id, name, price_monthly, features (list), is_active
users_plan: user_id, plan_id, status, started_at
goals: id, user_id, name, target_amount, saved_amount, target_date, priority
financial_profile: user_id, monthly_surplus, emergency_fund_status, insurance_status, risk_profile
generated_plans: id, user_id, created_at, plan_json
plan_snapshots: id, plan_id, month, actual_saved, status
products: id, name, type, rate, source_url, as_of_date
notifications: id, user_id, message, created_at, is_read

## Endpoints (FastAPI)
GET /plans -> list of plans with price and features
GET /me/plan -> the current user's plan and status
GET /goals -> the user's goals
POST /goals -> create a goal
GET /me/profile -> the user's financial profile
GET /me/notifications -> the user's notifications

## Rule
The app decides Free vs Premium only from GET /me/plan.
Nothing is hardcoded in Flutter.
