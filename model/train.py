"""Train a tiny model on real data: Fisher's 1936 Iris measurements.

Predicts iris species (setosa / versicolor / virginica) from four flower
measurements. The dataset ships inside scikit-learn, so no download is needed.
Accuracy doesn't matter here -- the point is having *something* to containerize.
"""
import os
import joblib
from sklearn.datasets import load_iris
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split

iris = load_iris()
X_train, X_test, y_train, y_test = train_test_split(
    iris.data, iris.target, test_size=0.2, random_state=42
)

model = LogisticRegression(max_iter=500).fit(X_train, y_train)
print(f"Test accuracy: {model.score(X_test, y_test):.2f}")

out_dir = os.environ.get("MODEL_DIR", "artifacts")
os.makedirs(out_dir, exist_ok=True)
joblib.dump(
    {"model": model, "classes": list(iris.target_names)},
    os.path.join(out_dir, "model.joblib"),
)
print(f"Saved model to {out_dir}/model.joblib")
