# Integración con el proyecto Spring Boot existente

Si ya existe el proyecto utilizado en CI/CD, no es necesario reemplazarlo.
Incorpore los archivos del laboratorio de manera gradual.

## 1. Dependencias

Agregar a `pom.xml`:

- `spring-boot-starter-jdbc`
- `spring-boot-starter-security`
- `spring-boot-starter-actuator`
- H2 con alcance `runtime`
- `commons-text:1.9`, únicamente para la práctica controlada de SCA

Mantener las dependencias existentes de pruebas y JaCoCo.

## 2. Base de datos

Copiar en `src/main/resources/`:

- `schema.sql`
- `data.sql`
- las propiedades H2 incluidas en `application.properties`

Si el proyecto ya usa una base de datos, renombrar estas tablas o activar los
datos mediante un perfil exclusivo llamado `lab`.

## 3. Código Java

Copiar los cuatro controladores y ajustar su declaración `package` al paquete
del proyecto existente:

- `ProductController`
- `CommentController`
- `AdminController`
- `AuthController`

Copiar también `SecurityConfig`. Si ya existe seguridad en el proyecto,
integrar deliberadamente la ruta `/api/admin/**` como pública en la rama de
laboratorio, en lugar de crear una segunda cadena de filtros.

## 4. Análisis local

Copiar `.semgrep.yml` en la raíz y ejecutar:

```bash
semgrep scan --config auto --config .semgrep.yml src/main/java
```

## 5. Contenedor

El `Dockerfile` suministrado reemplaza temporalmente al Dockerfile seguro. Se
utiliza para que Trivy y Hadolint produzcan hallazgos visibles. Conservar el
Dockerfile original en otra rama o tag.

## 6. Verificación mínima

```bash
mvn clean verify
mvn spring-boot:run
```

Verificar que respondan los cuatro endpoints indicados en `README.md`.

## 7. Recomendación de ramas

```text
main                  versión estable
lab/vulnerable        versión inicial del laboratorio
feature/fix-sqli      primera corrección
feature/fix-access    corrección de autorización
```

No fusionar `lab/vulnerable` en un proyecto que vaya a desplegarse fuera del
entorno académico.
