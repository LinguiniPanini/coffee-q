# CoffeeQ

Luis Alberto González Escamilla

## Descripción del problema

CoffeeQ: Sistema de procesamiento de órdenes de café basado en colas de mensajes.

### Problema que busca resolver

En una cafetería universitaria, el horario pico del mediodía genera un volumen de pedidos que excede la capacidad de procesamiento del punto de venta. Cuando múltiples clientes realizan pedidos simultáneamente, el sistema se satura: se pierden órdenes, los tiempos de espera crecen y la experiencia del cliente se degrada.

CoffeeQ resuelve este problema desacoplando la recepción de pedidos de su procesamiento. En lugar de que cada pedido sea atendido de forma inmediata y secuencial, los pedidos se depositan en una cola de mensajes (Amazon SQS). Un consumidor independiente, ejecutándose en una instancia EC2, extrae los pedidos de la cola a su propio ritmo y los registra en una base de datos relacional (Amazon RDS PostgreSQL). De esta manera, sin importar cuántos pedidos lleguen al mismo tiempo, ninguno se pierde y todos quedan registrados para su preparación.

## Diagrama de la arquitectura

<img width="1373" height="549" alt="screenshot-2026-03-17_21-42-55" src="https://github.com/user-attachments/assets/d8689f8d-1bb6-4ff7-a4ed-f418979d4a40" />

**Componentes del diagrama:**

| Componente | Servicio AWS | Detalle |
| :---- | :---- | :---- |
| Productor | AWS CLI | Envía mensajes con formato Latte|2026-02-16 13:39:45 |
| Cola | Amazon SQS | coffee-orders-queue, VisibilityTimeout=30s, Long Polling=20s |
| Consumidor | Amazon EC2 | consumer.py — polling infinito |
| Base de datos | Amazon RDS | PostgreSQL 15, tabla coffee\_orders |
| Permisos | IAM Role | sqs:ReceiveMessage, sqs:DeleteMessage |

**Flujo:**

1. El productor envía un mensaje a SQS via aws sqs send-message  
2. El consumer en EC2 recibe el mensaje via receive\_message (long polling)  
3. El consumer parsea el mensaje e inserta en RDS (INSERT INTO coffee\_orders)  
4. Tras un INSERT exitoso, el consumer borra el mensaje de SQS (delete\_message)  
5. Si el INSERT falla, se hace rollback y el mensaje reaparece en SQS tras 30s

## Descripción del diagrama

CoffeeQ implementa una arquitectura orientada a eventos utilizando tres servicios principales de AWS: SQS, EC2 y RDS.

El flujo inicia cuando el productor simula el envío de órdenes de café desde una terminal local mediante AWS CLI. Cada pedido se envía como un mensaje con el formato \<tipo\_de\_café\>|\<timestamp\> hacia una cola estándar de Amazon SQS llamada coffee-orders-queue. Esta cola actúa como un buffer que absorbe el volumen de pedidos sin importar la velocidad a la que lleguen, garantizando que ninguna orden se pierda incluso durante picos de demanda.

En el lado del procesamiento, una instancia Amazon EC2 de tipo t3.micro ejecuta consumer.py, una aplicación Python que realiza polling infinito sobre la cola SQS. El consumer utiliza long polling con un tiempo de espera de 20 segundos, lo que significa que cada llamada a receive\_message mantiene la conexión abierta hasta que haya un mensaje disponible o se agote el tiempo. Cuando el consumer recibe un mensaje, lo parsea para extraer el tipo de café y el timestamp, y ejecuta un INSERT en la tabla coffee\_orders de la base de datos.

La base de datos reside en Amazon RDS con SQL. La tabla coffee\_orders almacena cada pedido con un identificador autoincrementable, el timestamp original, el tipo de café y un estado fijo created.

Un aspecto clave del diseño es el orden de operaciones: el consumer primero confirma la inserción en la base de datos (commit) y solo después elimina el mensaje de la cola (delete\_message). Si la inserción falla, se ejecuta un rollback y el mensaje permanece en SQS, reapareciendo automáticamente después del VisibilityTimeout de 30 segundos para ser reintentado. Esto asegura que nada se pierda.

La instancia EC2 obtiene sus permisos para interactuar con SQS a través de un IAM Role.

Link al repositorio

[https://github.com/LinguiniPanini/coffee-q/tree/master](https://github.com/LinguiniPanini/coffee-q/tree/master)

Link al video
