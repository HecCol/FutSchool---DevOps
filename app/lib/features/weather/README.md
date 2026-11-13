# Consulta de clima

El módulo consulta condiciones actuales a Open-Meteo desde la pantalla de
inicio del capitán. La ubicación se solicita solo cuando se toca **Usar mi
ubicación**; las coordenadas se redondean a dos decimales y no se guardan en
Firestore. Si el usuario no comparte GPS, puede consultar San Juan del Río.

La petición usa HTTPS y no requiere una clave API. La interfaz atribuye la
fuente a Open-Meteo. El clima es informativo y puede no reflejar exactamente
las condiciones de la cancha.
