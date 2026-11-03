# Start with a lightweight Python image
FROM python:3.13-slim

# Python logs are printed immediately to the container logs
ENV PYTHONUNBUFFERED=1

# Set the working directory inside the container
WORKDIR /app

# Copy the dependency list first
COPY requirements.txt .

# Install the Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Create a non-root user for the application
RUN useradd --create-home appuser

# Copy the application code into the container
COPY --chown=appuser:appuser . .

# Run the application as the non-root user
USER appuser

# Document the port used by the application
EXPOSE 5000

# Start the Flask application using Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]


