# Git and GitHub – a guide for the two of us

Git keeps track of every version of our files. GitHub is the website where the shared copy lives.
Each of us has a local copy on our Mac and syncs it with GitHub.

```
 Your Mac  ──push──▶  GitHub (shared copy)  ◀──push──  Partner's Mac
           ◀──pull──                         ──pull──▶
```

**Four words you need to know:**

| Word | Meaning |
|---|---|
| **Commit** | Save a "snapshot" of your changes locally, with a short description |
| **Push** | Send your commits up to GitHub |
| **Pull** | Download what your partner has pushed |
| **Repository (repo)** | The project folder that Git keeps track of |

We use **GitHub Desktop** (a normal Mac app with buttons), not the Terminal.

### Website or app?

| github.com (website) | GitHub Desktop (app) |
|---|---|
| Create an account | Connect the folder on your Mac to GitHub |
| Invite your partner | Pull: get your partner's changes |
| Issues and the board: who does what, and when | Commit + Push: send your changes |
| Browse files and history | Works together with RStudio |

The website will look **empty** until the repo has been published from GitHub Desktop (step A5). That is normal.

---

## Part A – Ari sets it up (once, ~15 min)

1. **Create an account** at <https://github.com> (student email recommended; search "GitHub Student Developer Pack" for free Pro).
2. **Install GitHub Desktop**: <https://desktop.github.com> → sign in with the same GitHub account.
3. **Move the folder off the Desktop** (recommended): if Desktop/Documents sync with iCloud, iCloud and Git can conflict.
   Create the folder `~/GitHub/` (Finder → Go → Home → new folder "GitHub") and move `toll-accidents-catalonia` into it.
4. In GitHub Desktop: **File → Add Local Repository…** → choose `toll-accidents-catalonia`.
   It says the folder is not a repository yet → click **"create a repository"** → **Create Repository**.
   The first commit is created automatically.
5. Click **Publish repository** at the top. **Keep "Keep this code private" ticked.** → Publish.
6. On github.com: refresh, open the repo → **Settings → Collaborators → Add people** → enter your partner's GitHub username.

Do **not** click "Create repository" on the website – that makes an empty repo that is not connected to our folder.

## Part B – Partner (once, ~10 min)

1. Create a GitHub account and install GitHub Desktop (as A1–A2).
2. Accept the invitation (sent by email, or see notifications on github.com).
3. GitHub Desktop: **File → Clone Repository…** → choose `toll-accidents-catalonia` → choose `~/GitHub/` as location → Clone.

Done – we now have the same folder, the same dataset and the same code.

**First test together:** one of us edits a line in `README.md` → Commit → Push. The other clicks Pull and sees the change. That is the whole cycle.

---

## Daily workflow (do this EVERY time)

1. **Before you start:** GitHub Desktop → **Fetch origin** → **Pull origin** (if the button appears).
2. **Work** in RStudio as usual (always open the project via `toll-accidents-catalonia.Rproj`).
3. **When you finish a piece of work:** GitHub Desktop shows your changes on the left.
   Write a short summary at the bottom (e.g. `Add ex_toll variable and yearly plot`) → **Commit to main**.
4. **Push origin** at the top.

> Rule: **Pull before you start – push when you're done.** Commit often, several times per session is fine.

**Good commit messages** say *what* and ideally *why*: `Remove year/date from features (leakage)` is good; `fix` or `changes` is useless two weeks later.

## How to avoid conflicts

- **Split the work by file.** E.g. `R/02_missing_values.R` (Ari) and `R/03_ex_toll.R` (partner), instead of both editing the same script.
- **Never edit the original data** in `data/raw/`. Write new files to `data/processed/`.
- Pull before you start.

**If a conflict happens anyway:** GitHub Desktop tells you which file. Open it and you'll see:

```
<<<<<<< HEAD
your version
=======
partner's version
>>>>>>> origin/main
```

Keep what is correct, delete the marker lines, save → **Commit merge** → **Push**. Ask each other if unsure – never delete your partner's work.

## Who does what, and when – Issues and the Project board

1. On github.com → the repo → **Issues → New issue**. One issue = one concrete task.
   Set the **Assignee** (who) and put the deadline in the title or use a Milestone.
2. **Projects → New project → Board**: columns *Todo / In progress / Done*. Add the issues and drag them between columns.
3. Write `closes #3` in a commit message and issue #3 closes automatically when you push.

**Suggested first issues:**

| # | Task | Who | Due |
|---|---|---|---|
| 1 | Run `01_first_look.R` and make the monthly plot in ggplot2 | | before meeting |
| 2 | Overview of missing values (NA, 999, Unspecified) per variable and year | | before meeting |
| 3 | Create `ex_toll` variable from `road` + cross-table against `road_type` | | before meeting |
| 4 | Before/after shares for 5–6 key variables | | before meeting |
| 5 | Make 2–4 slides + list of questions for Marta | | before meeting |
| 6 | Decide time window and validation strategy (after meeting) | | |
| 7 | First model: logistic regression | | |

## The report

Write the report in **Google Docs / Word Online** (or Overleaf), not in Git. Save figures from R into `figures/` and insert them from there.

## Cheat sheet

| I want to … | Do |
|---|---|
| get my partner's changes | Fetch origin → Pull origin |
| save my work | write a message → Commit to main → Push origin |
| see what changed | the **History** tab |
| undo a commit | History → right-click → **Revert changes in commit** |
| undo changes I haven't committed | right-click the file under Changes → **Discard changes** |
