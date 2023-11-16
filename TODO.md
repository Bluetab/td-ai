# CI/CD

[x] remove python infrastructure from the pipeline

# GenAi Module

[ ] Error when searching for the first time, (not loaded collection)
[ ] Load all concepts instead of taking 10
[ ] Handle TdCluster, Milvus and NxServings errors on GenAi
[x] Handle index and predictions params with changeset before passing to GenAi
[x] Apply mapping and index params when creating index

---

TD-6140 As a user I want to request an AI system to suggest me data to complete my structure Note.info

[TD-6140]
https://jira.bluetab.net/browse/TD-6140
As a user I want to request an AI system to suggest me data to complete my structure Note.
Inicio: 31/10/2023
Fin:

td-web-modules: https://gitlab.bluetab.net/dgs-core/true-dat/front-end/td-web-modules/-/merge_requests/1031
td-i18n: https://gitlab.bluetab.net/dgs-core/true-dat/back-end/td-i18n/-/merge_requests/93
td-ai: https://gitlab.bluetab.net/dgs-core/true-dat/back-end/td-ai/-/merge_requests/new?merge_request%5Bsource_branch%5D=feature%2Ftd-6140
td-dd: https://gitlab.bluetab.net/dgs-core/true-dat/back-end/td-dd/-/merge_requests/new?merge_request%5Bsource_branch%5D=feature%2Ftd-6140
td-cluster:
td-core:
kong-setup: https://gitlab.bluetab.net/dgs-core/true-dat/back-end/kong-setup/-/merge_requests/92

export TD_OPENAI_API_KEY="---"

Include in templates option to select which fields may have a suggested value.
Include a new permission in notes to define who is able to request suggested values for a note
In case that the user has permission when modifying a note, a button to get suggestions will be displayed.
When clicking on the button API for td-ai will be called with following information:
Structure ID
Structure metadata
Structure profiling
Fields to be suggested with following information:
Field name
Field description
Field definition: Type of data, fixed values, etc.
Response provided by td-ai API will be used to populate corresponding fields in Note form.

---

En la gestion de plantillas una opcion en el campo, donde esta el widget.
permitir sugerencias Inteligencia Artificial, completar con IA.
Ahora solo con notas, pero va a mostrarse en todas las plantillas.

La esructura con una nota. ( extrainfo)
Editar, en el formulaio alguno de los campos de la nota esyta

- crear un permiso en las notas ( sugerencias IA)
  permiso sobre el dominio y ademas la plantilla tiene campos de Sugerencia de inteligencia artifical.
  un bton a la derecha. rellenar con Inteligencia artifica.
  el boton llamaria a la API.
  le pasas el id, y lo que necesite
  los campos que quieres que te rellene y para campo le pasas el nombre la descripción. definicion, valor fijo, lista de valores, la definición de la plantilla
  Td-IA
  Como se lo voy a mandar y como se va recibir.

con lo que te retorne, te rellene los campos y que se vea la diferencia de cuales son los que te rellenan
boton discreto a la derecha.

Tareas:

JIRA:
[] Documentar la parte del mappings
[] explicar como se utilian las nuevas APIS
[] No hay permisos para las APIS (No hay autentificación para la creación de promts y resource mappings)
[] añadir las variables de entorno al README.
[] Añadir sudo apt-get install inotify-tools para develop en linux
[] Unicamente se podra realizar una sugerencia sobre: fixed list y key/value list,
los que dependeran de otros valores y jerarquias no esta considerado en esta tarea
[] Revisar checkbox
[] Revisar los valores multiples
[] Hacer el Jira de cosas por hacer.
[] Se recomienda que en el system promtp especificar el resultado sea un rae json sin formatear.
[] No se pueden actualizar los propmts, lo ideal debería de crear otro y activarlo
[] Recomendaciones, si aplicacion el AI suggestions en la plantilla, te recomendamos que le pongas una descripción
[] crear una nueva tarea para comprobar los campos que son no editables en la parte del back ( problema de seguridad )
[] Error al crear una nota de cero, aparece el campo no editable deshabilitado, esto es un problmea por que no puedo crear la nota desde cero.
[] Crear una tarea nueva para el texto enriquecido y para las jerarquias???

Nuevas APIS:
La tabla de resource_mappings se emplea para saber cual es la información que se va a utilizar/mapear en la estructura para realizar la petición
de recomendación para la IA. consta de lo siguientes parámetros:

name: Se refiere al nombre se tendra el mappings, por ejemplo: "snowflake_structure"
fields: Es una lista de de objetos que tiene la siguiente estructura:
source: De que parte de la estructura se obtendrá la información.
target: nombre del elemento del que se obtendrá el valor ( no es necesario si el source se especifica)

      {"source": "type"},
      {"source": "metadata.database", "target": "database"},
      {"source": "metadata.schema", "target": "schema"},

Información de la API:

POST: {url}/api/resource_mappings
Parámetros:
name: Nombre
fields: listado de objetos por source y target

body Example:
{
"resource_mapping": {
"name": "snowflake_structure",
"fields": [
{"source": "type"},
{"source": "name"},
{"source": "metadata.database", "target": "database"},
{"source": "metadata.schema", "target": "schema"},
{"source": "class", "target": "structure_type"},
{"source": "group"},
{"source": "data_structure.system.name", "target": "system"},
{"source": "metadata.clustering_key", "target": "table_clustering_key"}
]
}
}

Nota: Si el mappgins no esta dado de alta en el servicio de td-ai, aunque el usuario tengan los permisos y se haya seleccionado el campo de AI suggestions en la plantilla
no aparecera el botón de sugerencia en las notas de las estructuras.

También se tienen los siguientes recursos:

Listar el listado de todos los resource_mappings
GET {api_url}/api/resource_mappings

Mostrar un resource_mappings
GET {api_url}/api/resource_mappings/:id

update
PATCH {api_url}/api/resource_mappings/:id
body:

POST /api/prompts
{
"prompt": {
"name": "data_structure_en_1",
"resource_type": "data_structure",
"language": "en",
"system_prompt": "You are a system that completes the value for various fields. You will receive some information about a Data Structure and the list of fields with their name and description. Return a JSON object with fields",
"user_prompt_template": "Data Structure: {resource} - Fields: {fields}",
"resource_mapping_id": 1,
"provider": "openai",
"model": "gpt-3.5-turbo"
}
}

    /api/prompts/set_active
    /api/suggestions

kong-setup
[x] Nuevas rutas de td-ai para guardar la información de los promts, resource mappings y seggestions

td-auth:
[x] Añadir un nuevo permiso (Sugerencias IA)

td-web-modules:
[-] Quitar los estilos
[x] quitar jerarquia y texto enriquecido, para las opciones de generacion de sugerencias
[x] fixed value, kye/value list y text,
[x] si se edita y no esta con la opción de editable,
no deberá mostrar sugerencias de IA (mostrar solo cuando es nueva nota)
[x] captura de errores de la resputesta de la IA
[x] mirar si el puede añadir el enriched
[x] Cuando se edita la nota. no esta viniendo el permiso
[-] Como se a agregado la accion de generar ai, esta se ha puesto en la parte de los botones de tres puntitos.
[x] añadir el checkout de completar con IA en la sección del widweg de las plantillas
[x] añadir el botón para lanzar la peticion de sugerencia comprobación de los permisos para editar y enviar peticion a la AI
[x] añadir la API para la petición de sugerencia
[-] Añadir el swr para lanzar la petición
[x] una vez obtenido los datos debera mostrar la información? ( como se tiene que mostrar )
[x] Comprobar todos los tipos de widgets que se pueden definir en las plantillas

[x] Bloquear el boton cuando se solicite la sugerencia
[x] sugerencias con los multiples valores.

td-dd:
[x] Comprobar perfilado en la parte de los fields para las estructuras
R. Esta dentro del metadata el perfilado
[x] Enviar el permiso de sugerencia de AI en la parte de las notas
[x] realizar la petición a td-ai para obtener la información
[x] Tests
[x] Qué pasa cuando tarda mucho la petición??? retornar un error???
[x] Se tiene que verificar el permiso de sugerencia
[x] Se tiene que comprobar el permiso de los dominios
[x] añadir el user_id a la peticion.

td-ia:
[x] verificar el promtp ya que si no existe no debería de retornar la validación de permitir generar
[x] Retornar error invalid prompt
[x] cambiar el schema de promtp para que sea text
[x] cambiar el schema de sugesstion para que sea un text
[-] No se tiene la API para obtener los datos de las respuestas?
Si que viene.
[x] Realizar la petición a chatgpt para obtener la información
[x] Poder realizar peticiónes en multi idioma
[x] creación de una tabla para guardar diferentes promts ( tener uno por activo ).
identificador, lenguaje, promts, user_id.
[x] tabla para guardar el historial de las respuestas que te da la información
[x] Tabla para guardar los promts
[x] tabla para guardar el resource mappings
[-] No hay autentificación para la creación de promts y resource mappings
[x] tener en cuenta la lista de valores posibles de un campo, si aplica. Si es un campo de seleccion multiple
que te de sugerencia de multiples valores. ( es la parte del promtp)
[-] Qué pasa con las jerarquias?
R. No se utiliza jerarquias de monento
[x] quitar el bang ya que si no esta activo el td.ai peta

Errores:
td-ai:

[x] Aparace al iniciar el servicio de td-ai: Instalación de una libreria. ver comentarios de JIRA

[error] `inotify-tools` is needed to run `file_system` for your system, check https://github.com/rvoicilas/inotify-tools/wiki for more information about how to install it. If it's already installed but not be found, appoint executable file with `config.exs` or `FILESYSTEM_FSINOTIFY_EXECUTABLE_FILE` env.
[warning] Could not start Phoenix live-reload because we cannot listen to the file system.
You don't need to worry! This is an optional feature used during development to
refresh your browser when you save files and it does not affect production.

Preguntas:
[-] Quién se encarga de obtener la información de las plantillas, según en la info de la tarea tengo que enviar la información
de la plantilla, pero esto es correcto??? no debería de tener comunicación directa td-ai con td-dd para obtener esta información
y procesarla?
[-] Donde se añade el permiso en auth
R. Es un permiso de notas modificar una nota ( si no puedes modificar la nota no sirve el permiso de la IA)
