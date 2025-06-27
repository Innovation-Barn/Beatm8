# 🗄️ Supabase Database Management

## 📦 Folder Structure
- `/migrations/` — SQL migration files for database schema versioning.

## 🚀 Workflow for Database Changes (Free Tier)

### ✅ Export Current Schema
1. Use Schema Visualizer → Copy as SQL (then clean it like this file).
2. Save as `001_initial.sql` inside `/infrastructure/supabase/migrations/`.

### ✅ Add a New Migration
1. Create a new SQL file:
   - Example: `002_add_new_table.sql`
2. Write SQL changes:
```sql
ALTER TABLE public.artists ADD COLUMN bio text;
```
3. Commit to GitHub:
```bash
git add infrastructure/supabase/migrations/002_add_new_table.sql
git commit -m "Add bio column to artists table"
git push
```

### ✅ Apply Migration to Supabase
- Open **Supabase SQL Editor**.
- Paste the SQL from the migration file and execute.

---