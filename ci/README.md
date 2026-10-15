# Integración continua

`ci.yml` se activa con push a `main` y pull requests hacia `main`.
Primero verifica README y las carpetas `app`, `ci` y `docs`.
Si pasa, llama a `flutter-validation.yml`, también disponible manualmente.

## Pipeline Flutter

1. Preparar Java 17 y Flutter 3.47.5.
2. Regenerar la configuración local de Android para el runner.
3. Resolver dependencias respetando `pubspec.lock`.
4. Verificar formato y analizar código.
5. Compilar Android: `flutter build apk --debug`.
6. Ejecutar pruebas: `flutter test --machine`.
7. Comunicar resultados en el resumen de GitHub Actions, incluso si falla una etapa.

Una falla detiene las etapas posteriores. No se ocultan errores para obtener un check verde.
Las pruebas actuales de widgets usan un servicio de autenticación de prueba:
no verifican el servicio Firebase real.

## Dónde ver errores y evidencias

En GitHub: **Actions → CI FutSchool → ejecución → Validar Flutter / flutter**.
Abre el paso rojo para leer el error completo. El resumen muestra cada etapa como
`success`, `failure`, `skipped` o `cancelled`.

Los resultados de pruebas se conservan en `futschool-test-results` (14 días),
si llegaron a ejecutarse. El APK debug se guarda en `futschool-debug-apk`
(7 días) cuando el proceso llega a ese paso. No es una release de producción.

Este pipeline ejecuta verificaciones reales; la página de simulación es independiente.
Un workflow configurado no equivale a una ejecución aprobada: revisa los checks del PR.
