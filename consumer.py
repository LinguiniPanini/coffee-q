import os
import boto3
import psycopg2

# Configuracion desde variables de entorno
sqs = boto3.client("sqs", region_name=os.environ.get("AWS_REGION", "us-east-1"))
QUEUE_URL = os.environ["SQS_QUEUE_URL"]

conn = psycopg2.connect(
    host=os.environ["RDS_HOST"],
    database=os.environ.get("RDS_DB", "coffee_shop"),
    user=os.environ.get("RDS_USER", "dbadmin"),
    password=os.environ["RDS_PASSWORD"]
)

print("Consumer iniciado. Esperando mensajes...")

while True:
    resp = sqs.receive_message(
        QueueUrl=QUEUE_URL,
        MaxNumberOfMessages=1,
        WaitTimeSeconds=20
    )

    for msg in resp.get("Messages", []):
        body = msg["Body"]
        print(f"Recibido: {body}")

        try:
            coffee_type, timestamp = body.split("|")

            cur = conn.cursor()
            cur.execute(
                "INSERT INTO coffee_orders (timestamp, coffee_type, order_status) VALUES (%s, %s, 'created')",
                (timestamp.strip(), coffee_type.strip())
            )
            conn.commit()
            cur.close()

            sqs.delete_message(QueueUrl=QUEUE_URL, ReceiptHandle=msg["ReceiptHandle"])
            print(f"Orden guardada: {coffee_type.strip()}")

        except Exception as e:
            conn.rollback()
            print(f"Error: {e}")