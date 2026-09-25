# Agilance Backend

Backend service for **Agilance**, providing APIs and core business logic for the application. This service is built with **Python** and is designed to be deployed either via **Docker** or directly as a **Python web service** (e.g., on Render).

---

## 🚀 Features

* REST API backend
* Dockerized for easy deployment
* Environment-variable based configuration
* Ready for cloud platforms like Render

---

## 🧱 Tech Stack

* **Python 3**
* **FastAPI** (Python 3.11)
* **Uvicorn** for serving
* **Docker** for containerization

---

## 📂 Project Structure

```text
.
├── main.py              # Application entry point
├── api.py               # API routes / logic
├── requirements.txt     # Python dependencies
├── Dockerfile           # Docker configuration
├── auto_db.sqlite       # Local SQLite database (dev only)
└── README.md
```

---

## 🛠️ Local Development

### 1. Clone the repository

```bash
git clone https://github.com/infiniterende/agilance-backend.git
cd agilance-backend
```

### 2. Create a virtual environment (recommended)

```bash
python -m venv venv
source venv/bin/activate  # macOS/Linux
venv\\Scripts\\activate     # Windows
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Run the server locally

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

The API should now be available at:

```
http://localhost:8000
```

---

## 🐳 Running with Docker

### Build the image

```bash
docker build -t agilance-backend .
```

### Run the container

```bash
docker run -p 8000:8000 agilance-backend
```

---

## ☁️ Deploying to Render

This project can be deployed on **Render** using Docker.

### Steps

1. Push the repository to GitHub
2. Go to **Render Dashboard → New → Web Service**
3. Select your GitHub repo
4. Choose **Docker** as the environment
5. Leave the start command blank (Render will use the Dockerfile)
6. Add any required **Environment Variables**
7. Click **Create Web Service**

Render will automatically build and deploy your service.

agilance-api.onrender.com - API service
agilance-backend.onrender.com - service worker


---

## 🔐 Environment Variables

Example environment variables:

```env
PORT=8000
DATABASE_URL=postgresql://user:password@host:5432/dbname
```

---

## 📌 Notes

* Ensure your app binds to `0.0.0.0` and uses the `$PORT` environment variable in production.
* Automatic deploys are triggered on every push to the connected branch in Render.