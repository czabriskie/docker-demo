# Student Lab: Your First Container

**You need:** Docker and git. You do **not** need Python.
Run every command in a Linux terminal (Linux, macOS, or WSL on Windows).

**What you're building:** a container that predicts the species of an iris flower (*setosa*, *versicolor* or *virginica*) from four measurements: sepal length, sepal width, petal length and petal width, all in cm.

**Where the data comes from:** the classic [Iris dataset](https://archive.ics.uci.edu/dataset/53/iris). It has 150 real flowers (50 of each species), measured by botanist Edgar Anderson and published by statistician Ronald Fisher in 1936. A copy ships inside the scikit-learn Python library, so the build loads it from there (`load_iris()` in `model/train.py`) and downloads nothing.

---

### Step 1: Get the code
```bash
git clone https://github.com/czabriskie/docker-demo.git docker-demo
cd docker-demo
```

### Step 2: Build the image
```bash
docker build -t iris-api .
```
✅ You should see `Test accuracy: ...` scroll past. The model was trained *inside* the build.

### Step 3: Run the container
```bash
docker run --rm -p 8080:8080 iris-api
```
Leave this running. Open a **second terminal** for the next step.

### Step 4: Ask it a question
```bash
curl -X POST localhost:8080/predict \
  -H "Content-Type: application/json" \
  -d '{"sepal_length":5.1,"sepal_width":3.5,"petal_length":1.4,"petal_width":0.2}'
```
✅ You should get back `"species":"setosa"`.

🎯 **Try it:** change the four numbers to `6.7, 3.0, 5.2, 2.3`. Which species do you get now?

Stop the container with **Ctrl+C** in the first terminal.

### Step 5: Look inside
```bash
docker run --rm -it iris-api bash
python --version
ls artifacts
exit
```
💡 That Python lives in the container, not on your computer.

### Step 6: Use it as a dev environment
```bash
./dev.sh python -m pytest
```
✅ You should see `1 passed`. Your code folder is shared with the container, so any edit you make shows up inside it straight away.

---

**Done!** You built an image, ran a container, called a model API, and used a container as a dev environment.

**Bonus:** open `PRESENTATION.md` to see how the same image is deployed to AWS.
