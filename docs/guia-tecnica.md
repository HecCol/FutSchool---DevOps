# Guía técnica de FutSchool

Este archivo reúne arquitectura, configuración, ejecución y decisión de autenticación. El contenido describe lo registrado en los documentos recibidos al 2026-10-06; no acredita una nueva verificación del código, Firebase ni GitHub Actions.

## Arquitectura del cliente

`main.dart` inicializa Firebase con configuración nativa Android.
`app/app.dart` escucha `AuthService.sessionChanges` y muestra login o bienvenida.
La transición depende de una sesión Firebase, no de aceptar campos localmente.

| Capa | Ruta dentro de `app/lib/` | Responsabilidad |
| --- | --- | --- |
| Presentación | `features/auth/presentation/` | Formulario, carga, validación y errores |
| Dominio | `features/auth/domain/` | Contrato del acceso y errores para la UI |
| Datos | `features/auth/data/` | Firebase Auth y Google Sign-In |
| Aplicación | `app/` | Tema y pantalla según sesión |
| Inicio | `features/home/presentation/` | Bienvenida y cierre de sesión |

### Flujo de acceso

Correo: formulario → Firebase → estado de sesión → bienvenida.
Google Android: selector de cuenta → ID token → credencial Firebase → sesión.
Google web usa popup Firebase y opciones explícitas de la app web registrada.

Durante el envío se bloquean ambos botones. La contraseña se oculta de forma
predeterminada y no se registran credenciales en logs. El cierre termina la
sesión Firebase; no elimina la cuenta Google del dispositivo.

### Límites

Registro de correo, recuperación de contraseña, roles, perfiles y torneos
siguen pendientes. Firebase Auth identifica al usuario; los permisos del
futuro backend o servicio de datos requieren autorización independiente.
No se otorgan permisos por ocultar botones en la interfaz.

Android y web tienen configuración Firebase. Los esquemas OAuth iOS y escritorio
están pendientes. Release aún utiliza firma de desarrollo; producción requiere
un certificado definitivo. Las carpetas reservadas no implican funciones listas.

---

## Firebase y Google Sign-In

### Configuración incorporada

- Proyecto: `futschool-2ef84`.
- Paquete Android: `mx.futschool.futschool`.
- Archivo: `app/android/app/google-services.json`, proporcionado por el propietario.
- Google Services configurado en Gradle Kotlin DSL.
- Plugins Flutter: `firebase_core`, `firebase_auth` y `google_sign_in`.
- Web: opciones proporcionadas por el propietario en
  `app/lib/app/firebase_web_options.dart`, usadas al inicializar Firebase web.

Elegir Kotlin en la consola es compatible con Android en Flutter. Los plugins
Flutter aportan los SDK; no se añade una segunda app ni dependencias duplicadas.

Se versiona el JSON de cliente para configurar este proyecto Android. Cuentas
de servicio, certificados privados y tokens administrativos se excluyen. La
autorización y restricciones de API se administran en Firebase/Google Cloud.

### Pendientes antes de probar

1. Confirmar Correo electrónico/contraseña habilitado. La captura proporcionada
   confirma Google habilitado.
2. Agregar huellas en Configuración del proyecto → Tus apps → Android:

   - SHA-1: `29:DD:E4:4F:9C:6C:28:24:E4:8A:6E:B4:77:15:16:36:09:8E:1B:E6`
   - SHA-256: `FD:C6:60:4E:E3:68:DA:F4:FF:2E:75:C0:CA:C0:35:DA:64:CE:9B:19:15:0E:69:F9:D2:3D:45:4E:97:30:EC:A8`

3. Descargar nuevamente el JSON tras registrar huellas. El archivo recibido
   contiene cliente OAuth web, pero no cliente Android vinculado a SHA-1.
4. Confirmar que la cuenta de prueba informada aparece en la lista Usuarios;
   no hay registro de cuentas en la UI de FutSchool.
5. Cuando se autoricen pruebas, verificar acceso, cancelación, errores,
   persistencia y cierre en un dispositivo Android con Google Play.

Cada desarrollador debe registrar sus propias huellas sin compartir la clave
privada. Producción requiere firma definitiva y huellas Google Play si aplica.

### Teléfono mediante navegador

La app web está registrada y sus opciones se incorporaron el 2026-10-06.
El acceso por correo y el popup Google usan Firebase Authentication.
No se crea automáticamente una cuenta de prueba ni se agrega Analytics.

Para probar localmente, iniciar `flutter run -d web-server --web-port 5318`
y abrir `http://localhost:5318`. En Authentication → Configuración → Dominios
autorizados confirmar `localhost`; si se usa `127.0.0.1`, autorizar también ese
host. Cualquier dominio futuro del enlace para teléfono requiere autorización.
El túnel y el despliegue siguen pendientes. Las opciones cliente no prueban
que el acceso con una cuenta real funcione ni habilitan los proveedores.

### Cuenta de prueba

El propietario informó la creación de una cuenta el 2026-10-06. La captura
recibida muestra el formulario de alta todavía abierto y la lista sin usuarios;
su guardado no está confirmado por evidencia posterior.

1. En Authentication → Usuarios, confirmar que el usuario esté listado.
2. Confirmar Correo electrónico/contraseña en Método de acceso.
3. Abrir la app e introducir las credenciales de forma privada.
4. Comprobar bienvenida, persistencia y cierre antes de registrar resultados.

No se publica el correo, contraseña ni la captura que contiene credenciales.
La contraseña visible en esa captura debe reemplazarse antes de usar la cuenta.
La tabla de resultados reales continúa vacía para que el propietario la complete.

### Referencias

- [Flutter](https://firebase.google.com/docs/flutter/setup).
- [Google Sign-In](https://firebase.google.com/docs/auth/flutter/federated-auth).
- [Android](https://firebase.google.com/docs/android/setup).

---

## Ejecutar FutSchool localmente

### Flutter instalado en PATH

```sh
cd app
flutter pub get
flutter run -d web-server --web-port 5318
```

Abrir `http://localhost:5318` en el navegador del mismo equipo. Usar web-server
evita depender del arranque automático de Edge en modo de depuración.

### Equipo Windows de desarrollo actual

Desde la carpeta `FutSchool---DevOps/app`, en PowerShell:

```powershell
$taskFlutter = (Resolve-Path "../../tmp/framework-tools/flutter-3.47.5/bin/flutter.bat").Path
& $taskFlutter pub get
& $taskFlutter run -d web-server --web-port 5318
```

La ruta al SDK es local a este workspace; otros equipos deben instalar Flutter
y usar su propia ruta. Mantener la terminal abierta; `q` detiene el servidor.
Si el puerto está ocupado, detener la instancia anterior o elegir otro puerto.

Si Windows informa que los plugins requieren symlinks, habilitar Modo de
desarrollador desde Configuración. Para abrir esa página:

```powershell
Start-Process "ms-settings:developers"
```

### Firebase y teléfono

La app utiliza opciones web reales; confirmar `localhost` en Dominios
autorizados de Firebase para el popup Google. Ver [Firebase](#firebase-y-google-sign-in).
El enlace localhost solo funciona en el equipo que sirve la app; un teléfono
requiere acceso de red o un enlace externo y su dominio autorizado.

No hay enlace externo publicado ni cuenta de prueba confirmada por esta entrega.
La configuración no crea usuarios automáticamente. La autenticación real y
sus resultados se registran por separado en la plantilla de validación.

---

## ADR 0001 · Firebase Authentication

- Fecha: 2026-10-04.
- Estado: aceptada por el propietario; acceso real pendiente de validación.

### Contexto

El cliente Flutter no tenía backend de autenticación. El propietario solicitó
correo/contraseña y Google, eligió Firebase y proporcionó configuración Android.

### Decisión

Usar Firebase Authentication detrás de `AuthService`. Google Sign-In proporciona
el ID token para obtener sesión Firebase. Separar widgets, contrato y adaptador;
presentar errores comprensibles sin registrar credenciales.

### Consecuencias

No se implementa almacenamiento propio de contraseñas. Se requiere OAuth y
certificados por plataforma. La dependencia del proveedor y límites de uso se
revisarán antes del lanzamiento. Los roles se autorizan en servicios de datos o
backend, independientemente del estado visual. No se eligió base de datos ni se
desplegó infraestructura adicional.
