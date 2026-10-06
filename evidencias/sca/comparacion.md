# Comparación del análisis SCA

## Identificación

- Grupo: Grupo 5
- Repositorio: https://github.com/AbelitoAL/Lab3-CI-Seguro-con-SAST-y-SCA (rama `lab/sca-sbom`)
- Commit de partida (`main`): `584fd8d9b9ce6d1ac4ef6d41cfbabc0f0f7ae3dc`
- Commit anterior (vulnerable): `afb66ec439807d45112061e792a116cb62f51140`
- Commit posterior (corregido): `cb35cffb83cfbfacb1b2fab5d6119c7026c22324`
- Ejecución anterior: análisis local con Docker — evidencias en `antes-afb66ec/`. GitHub Actions: https://github.com/AbelitoAL/Lab3-CI-Seguro-con-SAST-y-SCA/actions/runs/37504281476 (falla en el paso "Quality gate HIGH y CRITICAL")
- Ejecución posterior: análisis local con Docker — evidencias en `despues-cb35cff/`. GitHub Actions: https://github.com/AbelitoAL/Lab3-CI-Seguro-con-SAST-y-SCA/actions/runs/37504365558 (falla en el mismo paso por los hallazgos restantes)
- Pull request: https://github.com/AbelitoAL/Lab3-CI-Seguro-con-SAST-y-SCA/pull/1
- Versión de Trivy: 0.74.0 (`aquasec/trivy:0.74.0`), CycloneDX Maven Plugin 2.9.3 (spec 1.6)
- Fecha y hora de los análisis: 6 de octubre de 2026 — anterior 13:18 (UTC-4), posterior 13:20 (UTC-4)

Entorno local: Java 21.0.2, Maven 3.9.11, Docker 29.6.2. `mvn -B clean verify` terminó en
`BUILD SUCCESS` (2 pruebas, 0 fallos) en el commit de partida y después de la corrección.

## Dependencias exploradas (paso 2)

| Dependencia | Versión resuelta | Directa/transitiva | Quién la incorpora |
|---|---|---|---|
| `org.springframework.boot:spring-boot-starter-web` | 3.5.14 | Directa | `pom.xml` (versión heredada de `spring-boot-starter-parent` 3.5.14) |
| `org.apache.tomcat.embed:tomcat-embed-core` | 10.1.54 | Transitiva | `spring-boot-starter-web` → `spring-boot-starter-tomcat` |
| `com.fasterxml.jackson.core:jackson-databind` | 2.21.2 | Transitiva | `spring-boot-starter-web` → `spring-boot-starter-json` |

El árbol tiene más componentes que el POM porque cada starter declara a su vez sus propias
dependencias y Maven las resuelve de forma transitiva: el POM declara 8 dependencias (6 de
aplicación y 2 de pruebas) y el SBOM, que excluye el scope `test`, inventaría 53 componentes.
Las dependencias sin `<version>` reciben la versión del BOM gestionado por el parent de Spring Boot.

Control del paso 3: `tomcat-embed-core` aparece en el SBOM como
`pkg:maven/org.apache.tomcat.embed/tomcat-embed-core@10.1.54?type=jar`.

## Ficha del hallazgo (paso 5)

| Campo | Resultado |
|---|---|
| Componente y versión instalada | `org.apache.commons:commons-text` 1.9 |
| CVE o identificador del hallazgo | CVE-2022-42889 ("Text4Shell") |
| Severidad reportada | CRITICAL |
| Versión corregida, si aparece | 1.10.0 |
| Directa o transitiva | Directa (declarada en `pom.xml`) |
| Uso del componente en nuestra aplicación | Ninguno: no hay imports de `org.apache.commons.text` en `src/`. Se agregó solo como caso didáctico, por lo que la API de interpolación vulnerable no se invoca. |
| Cambio propuesto y pruebas necesarias | Actualizar a 1.10.0 (o eliminar la dependencia al cerrar la práctica); ejecutar `mvn -B clean verify`, regenerar el SBOM y repetir el análisis. |

## Hallazgo seleccionado

| Campo | Antes | Después |
|---|---|---|
| Componente | `org.apache.commons:commons-text` | `org.apache.commons:commons-text` |
| Versión resuelta | 1.9 | 1.10.0 |
| CVE seleccionado | CVE-2022-42889 | CVE-2022-42889 |
| Severidad reportada | CRITICAL | No reportado |
| Presencia del hallazgo | Sí | No |
| Estado del quality gate | Falla (exit 1): 24 hallazgos — 16 HIGH, 8 CRITICAL | Falla (exit 1): 23 hallazgos — 16 HIGH, 7 CRITICAL |

Totales del reporte completo: antes 52 (8 CRITICAL, 16 HIGH, 23 MEDIUM, 5 LOW); después 51
(7 CRITICAL, 16 HIGH, 23 MEDIUM, 5 LOW).

## Análisis

1. **¿La dependencia era directa o transitiva?**
   Directa. `commons-text` está declarada en `pom.xml` con versión explícita; a su vez trae
   `commons-lang3` 3.17.0 como transitiva.

2. **¿Qué cambio se realizó y por qué?**
   Se cambió la versión de `commons-text` de 1.9 a 1.10.0 en `pom.xml`, que es la primera
   versión que corrige CVE-2022-42889 según el propio reporte de Trivy (`FixedVersion: 1.10.0`).
   Es el mínimo histórico para este caso, no una recomendación de versión vigente.

3. **¿Qué pruebas se ejecutaron para verificar compatibilidad?**
   `mvn -B clean verify` (2 pruebas, 0 fallos, `BUILD SUCCESS`),
   `mvn dependency:tree -Dincludes=org.apache.commons:commons-text` (resuelve 1.10.0) y la
   regeneración del SBOM con `makeAggregateBom`. Como la aplicación no usa la biblioteca, el
   riesgo de incompatibilidad es mínimo.

4. **¿Qué evidencia muestra que desapareció el hallazgo seleccionado?**
   - `antes-afb66ec/bom.json` contiene `commons-text@1.9`; `despues-cb35cff/bom.json` contiene `commons-text@1.10.0`.
   - `antes-afb66ec/sca-report.json` y `sca-gate.txt` listan CVE-2022-42889; en `despues-cb35cff/` el CVE tiene 0 ocurrencias.
   - El conteo de CRITICAL baja de 8 a 7 y el total del gate de 24 a 23.

5. **¿Qué otros hallazgos o limitaciones quedan pendientes?**
   El quality gate **sigue en rojo** después de la corrección: quedan 23 hallazgos HIGH/CRITICAL
   en dependencias transitivas gestionadas por Spring Boot 3.5.14. No se desactivó ni se relajó el
   control.

   | Componente | Versión | CRITICAL | HIGH | Versión corregida indicada |
   |---|---|---|---|---|
   | `tomcat-embed-core` | 10.1.54 | 6 | 3 | 10.1.55 / 10.1.58 |
   | `spring-webmvc` | 6.2.18 | 1 | 2 | 6.2.19 (HIGH); 7.0.9 (CVE-2026-47884, CRITICAL) |
   | `jackson-databind` | 2.21.2 | 0 | 5 | 2.21.4 – 2.21.7 |
   | `jackson-core` | 2.21.2 | 0 | 3 | 2.21.4 / 2.21.7 |
   | `micrometer-core` | 1.15.11 | 0 | 2 | 1.15.12 |
   | `spring-expression` | 6.2.18 | 0 | 1 | 6.2.19 |

   - Remediación propuesta: actualizar `spring-boot-starter-parent` a un parche 3.5.x más reciente
     que arrastre estas versiones, en lugar de sobrescribir versiones una por una.
   - CVE-2026-47884 (`spring-webmvc`) solo indica corrección en la línea 7.0.x: exige evaluar una
     migración mayor o una excepción documentada; mientras tanto el gate seguirá bloqueando.
   - También quedan 23 MEDIUM y 5 LOW bajo el umbral (por ejemplo CVE-2025-48924 en `commons-lang3` 3.17.0).
   - Limitaciones: los archivos de evidencia guardados provienen del análisis local; los artifacts
     de GitHub Actions expiran a los siete días. Dependabot solo se activará cuando `.github/dependabot.yml` llegue a la rama
     predeterminada. Los resultados pueden cambiar al actualizarse la base de vulnerabilidades.
     `commons-text` puede eliminarse al cerrar la práctica porque no se usa.

## Cierre de la práctica

Después de conservar la comparación anterior, se retiró `commons-text` del `pom.xml` porque la
aplicación no la utiliza (sección 16 de la guía). `mvn -B clean verify` sigue en `BUILD SUCCESS`
(2 pruebas, 0 fallos) y `mvn dependency:tree -Dincludes=org.apache.commons:commons-text` ya no
devuelve el componente. El quality gate continúa bloqueando por los hallazgos pendientes de las
dependencias transitivas de Spring Boot descritos arriba.

La configuración de Dependabot se publicó además en la rama `ci/dependabot`, sin el resto del
laboratorio, para poder incorporarla a la rama predeterminada mediante un PR separado mientras
este PR permanece bloqueado por el gate.
