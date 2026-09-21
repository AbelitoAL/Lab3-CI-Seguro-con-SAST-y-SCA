# Guía docente: catálogo de vulnerabilidades

Este documento no debería entregarse antes de la actividad de descubrimiento.

| Endpoint o archivo | Vulnerabilidad intencional | OWASP 2025 | Herramienta esperada |
|---|---|---|---|
| `/api/products/search` | Concatenación de entrada en SQL | A05 Injection | Semgrep y ZAP/manual |
| `/api/comments/preview` | HTML sin codificación de salida | A05 Injection | Semgrep y ZAP/manual |
| `/api/admin/users/{id}` | Recurso administrativo sin autorización | A01 Broken Access Control | Semgrep/regla de configuración y ZAP/manual |
| `/api/auth/login` | Contraseña y secreto hardcoded | A04/A07 | Semgrep y Gitleaks según reglas |
| `/api/auth/login` | Contraseña registrada en logs | A02/A09 | Semgrep |
| `SecurityConfig` | `permitAll` y CSRF deshabilitado | A01/A02 | Semgrep |
| `application.properties` | H2 y Actuator expuestos; errores detallados | A02/A10 | Semgrep/ZAP y revisión |
| `pom.xml` | `commons-text:1.9` desactualizado | A03 | Trivy filesystem |
| `Dockerfile` | Usuario root, JDK completo y secreto en ENV | A02/A03 | Hadolint y Trivy |

## Pruebas controladas

Las demostraciones deben realizarse únicamente contra `localhost`.

### SQL Injection

Comparar una búsqueda normal con una entrada que modifique la condición SQL.
Evitar proporcionar cargas destructivas. El objetivo es demostrar lectura no
autorizada, no modificar la base de datos.

### XSS reflejado

Enviar una etiqueta HTML inofensiva, como `<strong>prueba</strong>`, y observar
que el servidor la devuelve como HTML. No es necesario ejecutar JavaScript para
demostrar la ausencia de codificación.

### Control de acceso

Invocar `/api/admin/users/1` sin cabecera de autenticación y comprobar que la
respuesta es `200`. La corrección deberá convertir esta expectativa en `401` o
`403`.

## Secuencia pedagógica sugerida

1. Ejecutar las pruebas y confirmar que el proyecto compila.
2. Probar los cuatro endpoints con datos normales.
3. Ejecutar Semgrep con reglas públicas y reglas locales.
4. Clasificar hallazgos verdaderos, falsos positivos y limitaciones.
5. Corregir una vulnerabilidad por rama o pull request.
6. Repetir el análisis y comparar evidencias.

## Consideraciones

- Todas las claves y datos incluidos son ficticios.
- No se deben almacenar datos reales en H2.
- El proyecto está diseñado para fallar controles de seguridad.
- Las pruebas funcionales pasan aunque la aplicación sea insegura. Esta
  diferencia es uno de los objetivos centrales del laboratorio.
