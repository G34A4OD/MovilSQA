# Evidencia de seguridad: procesamiento de documentos (#35)

Fecha: 2026-11-17. Base: `develop` en `261fe58`.

Se reprodujo con conexiones simuladas que una respuesta ClamAV con la palabra
`BROKEN` se interpretaba erróneamente como limpia y que una respuesta fragmentada
mediante `ReadableStream` fallaba. Se añadieron pruebas de regresión para esos
casos, respuestas incompletas, tiempos agotados, el contrato HTTP, veredictos
desconocidos y la confirmación de publicación fallida.

Comando ejecutado localmente:

```text
node --test supabase/functions/lookup-user/handler.test.mjs supabase/functions/process-document/handler.test.mjs supabase/functions/download-document/handler.test.mjs
```

Resultado: **22 pruebas aprobadas, 0 fallidas**. Se usaron únicamente datos y
respuestas simuladas; esta ejecución no valida un servidor antivirus real, ni
demuestra un despliegue remoto. No se ejecutaron SQL ni pruebas Android para
este cambio. Los resultados de CI y una revisión independiente se registran en
el PR.

Pendiente: acordar, configurar y probar un escáner real en un entorno controlado;
definir la reconciliación de copias cuando la confirmación del commit es incierta.
