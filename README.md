# Blackjack Bot: automate everything

You already know Git, Docker, Kubernetes and GitHub Actions. Today you use them for one
purpose: **making the computer do the boring work for you.**

We start with a boring chore: *"Which blackjack strategy wins the most?"* Checking one game by hand is
easy. Checking 1000 games for 6 strategies is not. So we climb the **automation ladder**, one rung at a time.

```
  Rung 5   TOURNAMENT   your strategy is scored automatically when you push   (Git + Actions)
  Rung 4   TRIGGER      GitHub runs the whole thing on push, on a button, on a timer (Actions)
  Rung 3   SCHEDULE     Kubernetes runs the bot every minute, nobody types anything (CronJob)
  Rung 2   PACKAGE      the bot runs the same way on every computer                  (Docker)
  Rung 1   SCRIPT       a loop plays 1000 games for you                              (shell)
  Rung 0   BY HAND      you type every game yourself                                 (you)
```

**The big idea of today:** automation is not about one tool. It is about answering
*"what should start this, and when?"*

| Rung | What starts the work? |
|------|-----------------------|
| 0 | You, every single time |
| 1 | You, once (the loop does the repeating) |
| 3 | The clock (a schedule) |
| 4 | An event (a push), a button, or the clock |

## Time plan (90 minutes)

| Time | Step | Topic |
|------|------|-------|
| 0:00 | [Step 1](#step-1---the-boring-chore-by-hand-8-min) | The chore by hand |
| 0:08 | [Step 2](#step-2---script-it-20-min) | Script it |
| 0:28 | [Step 3](#step-3---package-it-with-docker-12-min) | Package it (Docker) |
| 0:40 | [Step 4](#step-4---schedule-it-with-kubernetes-15-min) | Schedule it (Kubernetes) |
| 0:55 | [Step 5](#step-5---trigger-it-with-github-actions-20-min) | Trigger it (GitHub Actions) |
| 1:15 | [Step 6](#step-6---the-tournament-13-min) | The tournament |
| 1:28 | [Wrap-up](#wrap-up) | What you learned |

## What is in this repository

| File | What it is |
|------|------------|
| `blackjack.c` | A simple blackjack program. Same seed + same moves = same game. |
| `strategies/*.sh` | The "brains". Each file is a tiny script that decides **h**it or **s**tand. |
| `play.sh` | The robot player. Plays **one** game using a strategy. |
| `simulate.sh` | Plays **many** games with one strategy and prints a summary line. |
| `leaderboard.sh` | Runs **every** strategy and ranks them. |
| `Dockerfile` | Packages the program and the robot into an image called `blackjack-bot:1.0`. |
| `test.sh` | Checks that the robot gives the exact same numbers as always. |
| `Job.yaml`, `CronJob.yaml` | Kubernetes: run the bot once / run it on a timer. |
| `.github/workflows/ci.yml` | The pipeline: lint, test, leaderboard. |
| `solutions/` | The answer for Step 5. Try without it first! |

## Before you start

Check that your tools work:

```bash
git --version
docker run --rm hello-world
kubectl get nodes
```

`kubectl get nodes` must show a node that is `Ready` (use `minikube start --driver=docker` or Docker Desktop's
Kubernetes, as in the Kubernetes tutorial).

**Get the code:** this repository is a **template**. You make your own copy of it, and then clone your copy:

1. On the repository page on GitHub, click the green **Use this template** button (top right), then **Create a new repository**.
2. Choose yourself as the owner and give it a name, for example `blackjack-automation`.
3. Make it **Public** (this keeps GitHub Actions free) and click **Create repository**.
4. On your new repository, click the green **Code** button, copy the HTTPS address, and clone it:

```bash
git clone https://github.com/<your-username>/<your-repo-name>.git
cd <your-repo-name>
```

From now on, `git push` sends your work to **your own** copy. The original template is never changed.

**You also need a way to compile C** for Steps 1 and 2:

- Mac / Linux: `gcc -o blackjack blackjack.c`
- Windows (no gcc): use WSL or Codespaces, or this trick that works everywhere with Docker:

  ```bash
  docker run --rm -it -v "$PWD":/work -w /work gcc:14.2 sh
  ```

  Then run every command of Steps 1 and 2 inside that shell. Type `exit` when you are done.

---

## Step 1 - The boring chore, by hand (8 min)

Compile the game and play with seed 0:

```bash
gcc -o blackjack blackjack.c
./blackjack 0 s
```

`s` means *you stand straight away*. This is the strategy **always-stand**. Your job: **count how many of the
seeds 0 to 9 this strategy wins.** Run the command for seed 0, then 1, then 2, ... up to 9.

1. How long did it take you to check 10 games?
2. How long would 1000 games take? And 1000 games for 6 strategies?
3. Something odd happens at two of the seeds. Which ones? Read the error message. (Hint: the game was won already
   at the deal, so no move is allowed. See the same thing in `blackjack.c`, function `play`.)

> **Think:** this is exactly the kind of work a computer should do. Computers are bad at ideas and great at
> boring repetition.

---

## Step 2 - Script it (20 min)

### 2a. The shortest automation: a loop (3 min)

Type this in your terminal:

```bash
for seed in 0 1 2 3 4 5 6 7 8 9; do ./blackjack $seed s; done
```

All 10 games in a fraction of a second. (The two errors appear again, but the loop keeps going.)

### 2b. A strategy is just a tiny script (5 min)

Open `strategies/stand-on-16.sh`:

```sh
if [ "$1" -lt 16 ]; then echo h; else echo s; fi
```

It receives your current total (`$1`) and the dealer's visible card (`$2`) and prints `h` or `s`. Try it by hand:

```bash
sh strategies/stand-on-16.sh 12 K     # prints h
sh strategies/stand-on-16.sh 18 K     # prints s
```

Now open `strategies/smart.sh`. It also looks at the dealer's card. What does it do differently?

### 2c. The robot player (5 min)

`play.sh` is the robot. It plays one whole game: it asks the program for the state, asks the strategy for a move,
adds the move to the history, and repeats until the game is over. Run it:

```bash
./play.sh strategies/stand-on-16.sh 42
```

You should see: `You: J 8 (18) | Dealer: 4 8 Q (22) | Dealer busts! You win!`

Read `play.sh`. Find the line that asks the strategy for a move.

### 2d. Play 1000 games (7 min)

`simulate.sh` calls `play.sh` once per seed and counts wins, draws and losses:

```bash
./simulate.sh always-stand 1000
```

You should see:

```
always-stand: 1000 games | 394 wins | 54 draws | 552 losses | win rate 39.4%
```

(It takes a few seconds.) Now run the same for `smart` and `stand-on-16`, then run all of them at once:

```bash
./leaderboard.sh 1000
```

(about 40 seconds, six strategies times 1000 games = 6000 games you did not play by hand)

**Questions**

1. Which strategy is best? Which is worst?
2. Run `./simulate.sh smart 1000` twice. Why is the result *exactly* the same both times?
3. Run `./simulate.sh smart 10`. Why is the win rate less reliable than with 1000 games?

### Commit

```bash
git add .
git commit -m "Step 2: robot player and simulator"
git push
```

> **Rung 1 reached.** You wrote the work once, and the computer repeats it. But *you* still have to type the command.

---

## Step 3 - Package it with Docker (12 min)

Right now the robot only works on a computer that has `gcc` and a shell. Docker makes it work on any computer.

Open the `Dockerfile` and compare it to the one from the Docker tutorial. There are **two differences**:

1. The last stage is `alpine` instead of `scratch`. Why? (Hint: the robot is made of shell scripts. What do scripts need to run?)
2. `ENTRYPOINT` is now `simulate.sh`, and `CMD` gives the default arguments. So `docker run blackjack-bot:1.0` plays 1000 games with `stand-on-16`.

Build and run it:

```bash
docker build -t blackjack-bot:1.0 .
docker run --rm blackjack-bot:1.0
docker run --rm blackjack-bot:1.0 smart 200
```

The second run replaces the default arguments (`stand-on-16 1000`). You can still reach the game itself, because
the image contains it too:

```bash
docker run --rm --entrypoint /app/blackjack blackjack-bot:1.0 42 s
```

Now the safety net. `test.sh` runs the robot in the image and checks that the numbers are exactly the ones we
expect:

```bash
./test.sh
```

All tests must pass.

**Questions**

1. Check the image size with `docker images blackjack-bot:1.0`. Is it bigger or smaller than the `scratch` image? Why?
2. Why can a test check *exact* win counts like "85 wins"? (Remember the seed.)

### Commit

```bash
git add .
git commit -m "Step 3: Docker image works"
git push
```

> **Rung 2 reached.** The robot runs the same way anywhere. Still, a human has to type `docker run`.

---

## Step 4 - Schedule it with Kubernetes (15 min)

Now we remove the human. Let **time** start the robot.

Make sure your cluster is running and has the image:

```bash
kubectl get nodes
minikube image load blackjack-bot:1.0
```

(Docker Desktop's Kubernetes does not need the load step. With kind use `kind load docker-image blackjack-bot:1.0`.)

### 4a. One run: a Job (3 min)

```bash
kubectl apply -f Job.yaml
kubectl logs job/blackjack-bot-job
```

You should see `smart: 200 games | 84 wins | 21 draws | 95 losses | win rate 42.0%`.
(If you see `ContainerCreating`, wait a few seconds and run `kubectl logs` again.)

You started this one yourself. Now open `CronJob.yaml`.

### 4b. The automation: a CronJob (8 min)

Read the comments about `schedule`. The schedule `"* * * * *"` means *every minute*. Start it:

```bash
kubectl apply -f CronJob.yaml
kubectl get cronjob
```

Now **do nothing for a minute** and watch:

```bash
kubectl get jobs --watch
```

Press `Ctrl+C` to stop watching. A new Job appeared although nobody ran `kubectl apply`. Read what the robot did:

```bash
kubectl get pods
kubectl logs <name-of-one-of-the-pods>
```

**Try it yourself**

1. In `CronJob.yaml`, change the strategy `stand-on-16` to `smart`.
2. Remove the old CronJob and apply again: `kubectl delete -f CronJob.yaml` then `kubectl apply -f CronJob.yaml`.
3. Wait one minute and check that the new logs show `smart`.

**Questions**

1. What would the schedule `"0 9 * * *"` mean? And `"*/10 * * * *"`?
2. What happens if the robot needs more than a minute for a run? (Look at `concurrencyPolicy`.)
3. Run `kubectl get jobs`. How many old Jobs are kept? Which two lines in `CronJob.yaml` decide this?

### Clean up (important, otherwise it runs forever!)

```bash
kubectl delete -f CronJob.yaml -f Job.yaml
kubectl get jobs
```

### Commit

```bash
git add .
git commit -m "Step 4: CronJob uses the smart strategy"
git push
```

> **Rung 3 reached.** Time starts the robot. But it only runs on *your* cluster, and nothing checks that the code is still correct.

---

## Step 5 - Trigger it with GitHub Actions (20 min)

The pipeline in `.github/workflows/ci.yml` is already in the repository. Because you pushed, **it already ran!**

### 5a. Read the pipeline (5 min)

Open the **Actions** tab on GitHub and click the latest run. You see three jobs:

```
lint  ->  test  ->  leaderboard
```

1. Open the run page. At the top you find a **Blackjack leaderboard**. Which job wrote it, and with which special file? (Search for `GITHUB_STEP_SUMMARY` in `ci.yml`.)
2. In the **Artifacts** section at the bottom, download `leaderboard`. What is inside?
3. Why does `leaderboard` say `needs: test`? What would happen if `test` fails?

### 5b. Add two more triggers (7 min)

Look at the `on:` block at the top of `ci.yml`. It has two triggers: `push` and `pull_request`. Both are
**events**: something happens, so the pipeline starts.

Add two more triggers **under `pull_request:`**:

```yaml
  workflow_dispatch:        # a manual "Run workflow" button
  schedule:                 # a timer, same cron format as the CronJob
    - cron: "0 7 * * *"     # every day at 07:00 UTC
```

Be careful with the indentation: `workflow_dispatch` and `schedule` must line up with `push` and `pull_request`.
(Stuck? The answer is in `solutions/ci-with-schedule.yml`.)

Commit and push. Then go to **Actions**, click **CI** on the left, and press the new **Run workflow** button. The
pipeline runs without any commit.

```bash
git add .
git commit -m "Step 5: add button and daily schedule"
git push
```

> A scheduled workflow can start a few minutes late, and GitHub only runs it from the `main` branch. That is why we
> use the button for live demos.

Compare the three ways to start the pipeline now:

| Trigger | Who/what starts it |
|---------|--------------------|
| `push` / `pull_request` | an **event**: someone changed the code |
| `workflow_dispatch` | a **human**, with one click |
| `schedule` | the **clock** |

### 5c. Break it on purpose (8 min)

Does the pipeline really protect us? Let's check.

```bash
git checkout -b broken
```

In `blackjack.c`, change the dealer's rule:

```c
#define DEALER_STANDS_ON 17
```

to

```c
#define DEALER_STANDS_ON 10
```

The dealer now stops drawing too early. Before you push, **predict**: will the player win more or less? Then:

```bash
git add .
git commit -m "Make the dealer lazy"
git push -u origin broken
```

Watch the **Actions** tab:

1. Which job fails? Open its log. Which numbers are different from the expected ones?
2. Which job did **not** run, and why?
3. Was your prediction right? (Look at the `stand-on-16` numbers in the log. Are they higher or lower than expected?)

Now fix it: put the `17` back, commit, and push. The pipeline turns green again.

> This is the real power of automation: nobody has to remember to check. The pipeline checks **every** change, **every** time.

```bash
git checkout main
```

> **Rung 4 reached.** The pipeline starts by event, by button, or by the clock, and it stops bad code automatically.

---

## Step 6 - The tournament (13 min)

Now you use the whole ladder. **Your goal: invent a strategy that beats everyone on the leaderboard.**

1. Create a branch for your strategy (the name must start with `strategy-`):

   ```bash
   git checkout -b strategy-<your-name>
   ```

2. Copy the template and edit your rule:

   ```bash
   cp strategies/_template.sh strategies/<your-name>.sh
   ```

   The script gets `$1` (your total) and `$2` (the dealer's card) and prints `h` or `s`. Some ideas:
   - Stand earlier or later than the others?
   - Does the dealer's card change what you should do? (Look at `smart.sh`.)
   - What if you treat a dealer `A` differently?

3. Test your strategy locally on 200 games (about 1 second per 100 games):

   ```bash
   ./simulate.sh <your-name> 200
   ```

4. Push the branch. **The pipeline runs by itself** and puts your strategy on the leaderboard:

   ```bash
   git add strategies/<your-name>.sh
   git commit -m "Add strategy <your-name>"
   git push -u origin strategy-<your-name>
   ```

5. Open the run in the **Actions** tab. Where did you finish? All strategies play the same 1000 games, so the
   comparison is fair.

6. (Optional) Open a **pull request** from your branch to `main`. The pipeline runs on the PR too.

**Rules**

- Your strategy must print only `h` or `s`. Otherwise `play.sh` stops with an error and the leaderboard job fails.
- Don't change `blackjack.c`, `play.sh` or the other strategies. Only add your own file.
- Highest win rate after the pipeline finishes wins. A tie goes to whoever pushed first.

**Think about it**

- Can your strategy win *every* game? Why or why not?
- Could a strategy be great on seeds 0 to 999 but bad on other seeds? (That is called *overfitting*. Test your strategy with `./simulate.sh <your-name> 5000` and compare.)

---

## Wrap-up

You climbed the whole ladder:

```
  Rung 0   BY HAND    ./blackjack 0 s            (you, every time)
  Rung 1   SCRIPT     ./simulate.sh smart 1000   (you, once)
  Rung 2   PACKAGE    docker run blackjack-bot   (you, anywhere)
  Rung 3   SCHEDULE   CronJob                    (the clock, on your cluster)
  Rung 4   TRIGGER    GitHub Actions             (an event, a button or the clock, in the cloud)
  Rung 5   TOURNAMENT push a file, get a ranking (nobody)
```

**Remember three things:**

1. **If you do something more than twice, automate it.** Start with a loop.
2. **Every automation answers: what starts it?** You, a button, an event, or a clock.
3. **Automate the checking too.** Tests plus a pipeline mean mistakes are caught before anyone sees them.

### Where to go next

- Make the pipeline send you the leaderboard by e-mail or chat when it finishes.
- Let the daily run save its result in the repository automatically.
- Compare strategies with a statistics rule: is 41.9% really better than 41.2%?
- Publish the image to `ghcr.io` like in the Actions tutorial and run it from the registry in Kubernetes.

### Common problems

| Problem | Fix |
|---------|-----|
| `permission denied: ./simulate.sh` | `chmod +x *.sh strategies/*.sh` |
| `./blackjack: no such file` | Compile first: `gcc -o blackjack blackjack.c` |
| Strategy prints something else than `h`/`s` | Check for `echo` of debug text. The script may print only one letter. |
| `ErrImagePull` or `ErrImageNeverPull` in Kubernetes | Load the image: `minikube image load blackjack-bot:1.0` |
| CronJob shows no Jobs yet | Wait up to one minute after `kubectl apply` |
| The pipeline did not start on `git push` | Is the branch `main` or does it start with `strategy-`? |
| The `schedule` did not fire | It only works on `main` and can be late. Use the **Run workflow** button. |
| `lint` job fails | Read the log: Hadolint tells you which Dockerfile line is wrong. |

---

*`blackjack.c` comes from the blackjack tutorial project (CC0 license, see `LICENSE`).*
