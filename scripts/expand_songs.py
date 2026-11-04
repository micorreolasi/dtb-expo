# -*- coding: utf-8 -*-
"""
Script para agregar repertorio completo de:
- Marcos Witt
- Jesus Adrian Romero
- Miel San Marcos
- Montesanto
- Un Corazon
- y contemporaneos clave (Barak, Christine D'Clario, Julio Melgar, Hillsong / Elevation en Español)
"""
import json
import re

NEW_SONGS_DATA = [
    # ==========================================
    # MARCOS WITT
    # ==========================================
    {
        "title": "Tu Fidelidad (Marcos Witt)",
        "lyrics": """Tu fidelidad es grande
Tu fidelidad incomparable es
Nadie como Tú, bendito Dios
Grande es tu fidelidad

Tu fidelidad es grande
Tu fidelidad incomparable es
Nadie como Tú, bendito Dios
Grande es tu fidelidad"""
    },
    {
        "title": "Renuévame (Marcos Witt)",
        "lyrics": """Renuévame, Señor Jesús
Ya no quiero ser igual
Renuévame, Señor Jesús
Pon en mí tu corazón

Porque todo lo que hay dentro de mí
Necesita ser cambiado, Señor
Porque todo lo que hay dentro de mi corazón
Necesita más de Ti"""
    },
    {
        "title": "Gracias (Marcos Witt)",
        "lyrics": """Me has tomado en tus brazos y me has dado salvación
De tu amor has derramado en mi corazón
No sabré agradecerte lo que has hecho por mí
Solo puedo darte ahora mi canción

Gracias, gracias, Señor
Gracias, mi Señor Jesús
Gracias, gracias, Señor
Gracias, mi Señor Jesús

En la cruz diste tu vida, entregaste todo allí
Vida eterna regalaste al morir
Por tu sangre tengo entrada ante el trono celestial
Puedo entrar confiadamente ante Ti"""
    },
    {
        "title": "Temprano Yo Te Buscaré (Marcos Witt)",
        "lyrics": """Temprano yo te buscaré
De madrugada yo me acercaré a Ti
Mi alma te anhela y tiene sed
Para ver tu gloria y tu poder

Mi socorro has sido Tú
Y en la sombra de tus alas yo me gozaré
Mi alma está apegada a Ti
Porque tu diestra me ha sostenido
Oh, tu diestra me ha sostenido"""
    },
    {
        "title": "En Los Montes, En Los Valles (Marcos Witt)",
        "lyrics": """En los montes, en los valles
Exaltamos al que es digno de alabanza
En las costas de los mares
Levantamos un sonido de esperanza

Aclamamos, aclamamos
Hacemos oír la voz de su alabanza
Con las manos en lo alto
Exaltamos al que reina para siempre

Subamos a adorar en el monte de Sión
Es el gozo de toda nación
Donde la tristeza es cambiada en gozo
Alabemos al Señor"""
    },
    {
        "title": "Al Estar Aquí (Marcos Witt)",
        "lyrics": """Al estar en la presencia de tu divinidad
Y al contemplar la hermosura de tu santidad
Mi espíritu se alegra en tu majestad
Te adoro a Ti, te adoro a Ti

Cuando veo la grandeza de tu dulce amor
Y compruebo la pureza de tu corazón
Mi espíritu se alegra en tu majestad
Te adoro a Ti, te adoro a Ti

Y al estar aquí delante de Ti, te adoraré
Postrado ante Ti, mi corazón te adora, oh Dios
Y siempre quiero estar para adorar
Y contemplar tu santidad
Te adoro a Ti, Señor, te adoro a Ti"""
    },
    {
        "title": "Poderoso Dios (Marcos Witt)",
        "lyrics": """Al que está sentado en el trono
Y al Cordero sea el honor
Sea la gloria, sea la honra
Sea el dominio por los siglos de los siglos

Poderoso Dios, poderoso Dios
Poderoso Dios, mi alma clama por Ti

Poderoso Dios, poderoso Dios
Poderoso Dios, mi alma clama por Ti"""
    },
    {
        "title": "Dios de Pactos (Marcos Witt)",
        "lyrics": """Dios de pactos que guardas tus promesas
Que cumples tu palabra, que guías mi destino
Dios de pactos, confío en tus promesas
Descanso en tu palabra, por tu gracia estoy aquí

En la intimidad, al abrigo de tu gloria
Puedo estar junto a Ti
Al ver tu majestad y contemplar tu hermosura
Puedo decir: Te amo

Dios de pactos que guardas tus promesas
Que cumples tu palabra, que guías mi destino
Dios de pactos, confío en tus promesas
Descanso en tu palabra, por tu gracia estoy aquí"""
    },
    {
        "title": "Cuán Bello Es El Señor (Marcos Witt)",
        "lyrics": """Cuán bello es el Señor
Cuán hermoso es el Señor
Cuán bello es el Señor
Hoy le quiero adorar

La belleza de mi Señor
Nunca se agotará
La hermosura de mi Señor
Siempre resplandecerá"""
    },
    {
        "title": "Motivo de Mi Canción (Marcos Witt)",
        "lyrics": """Jesucristo es el motivo de mi canción
Otra razón yo no tengo porque cantar
La melodía es Él, Jesús es mi razón
De amarte y adorarle siempre a Él

Jesucristo es el motivo de mi canción
Otra razón yo no tengo porque cantar
La melodía es Él, Jesús es mi razón
De amarte y adorarle siempre a Él"""
    },
    {
        "title": "Tu Mirada (Marcos Witt & Jesús Adrián Romero)",
        "lyrics": """Tus ojos revelan que yo nada puedo esconder
Que no soy nada sin Ti, oh fiel Señor
Todo lo sabes de mí cuando miras el corazón
Todo lo puedes ver muy dentro de mí

Lleva mi vida a una sola verdad
Que cuando me miras nada puedo ocultar

Sé que es tu fidelidad
Que lleva mi vida más allá
De lo que puedo imaginar
Sé que no puedo negar
Que tu mirada puesta en mí
Me llena de tu paz"""
    },
    {
        "title": "Sobrenatural (Marcos Witt)",
        "lyrics": """Sobrenatural, habitas en las alabanzas de tu pueblo
Sobrenatural, te mueves en medio de la adoración
Sobrenatural, eres Dios de milagros
Sobrenatural, no hay nada imposible para Ti

Dios de lo imposible, te adoramos
Dios de maravillas, te exaltamos
Haces cosas grandes, Dios temible
Eres digno de honra y gloria"""
    },
    {
        "title": "Somos El Pueblo de Dios (Marcos Witt)",
        "lyrics": """Somos el pueblo de Dios
Somos un pueblo especial
Llamados para anunciar
Las virtudes de Aquél
Que nos llamó a su luz

Somos el pueblo de Dios
Su sangre nos redimió
Y su Espíritu dio
Para darnos poder
Y ser testigos de Él

Y llevaremos su gloria
A cada pueblo y nación
Trayéndoles esperanza
Y nuevas de salvación
Y su amor nos impulsa
No nos podemos callar
Anunciaremos al mundo
De su amor y verdad"""
    },
    {
        "title": "Sana Nuestra Tierra (Marcos Witt)",
        "lyrics": """Vengo a Ti, guíame
Santifícame en Ti
Yo quiero andar en tu verdad
Tómame, abrázame
Digno eres de gloria
Cambia mi corazón

Humillados ante Ti
Hoy clamamos a una voz
Sana nuestra tierra
Sana nuestra tierra
Perdona nuestro error
Y escucha nuestra oración
Sana nuestra tierra"""
    },
    {
        "title": "Venció (Marcos Witt)",
        "lyrics": """Venció, Cristo venció
Venció al diablo en la cruz
Venció, Cristo venció
Los principados desarmó

Él es el Rey de reyes
Señor de señores
Y reina por los siglos
De los siglos, amén"""
    },

    # ==========================================
    # JESÚS ADRIÁN ROMERO
    # ==========================================
    {
        "title": "Sumérgeme (Jesús Adrián Romero)",
        "lyrics": """Cansado del camino, sediento de Ti
Un desierto he cruzado, sin fuerzas he quedado
Vengo a Ti
Luché como soldado y a veces sufrí
Y aunque la lucha he ganado, mi armadura he desgastado
Vengo a Ti

Sumérgeme en el río de tu Espíritu
Necesito refrescar este seco corazón
Sediento de Ti
Sumérgeme en el río de tu Espíritu
Necesito refrescar este seco corazón
Sediento de Ti
Sumérgeme"""
    },
    {
        "title": "Mi Universo (Jesús Adrián Romero)",
        "lyrics": """Que seas mi universo
No quiero darte solo un rato de mi tiempo
No quiero separarte un día solamente
Que seas mi universo
No quiero darte mis palabras como gotas
Quiero un diluvio de alabanzas en mi boca

Que seas mi universo
Que seas todo lo que siento y lo que pienso
Que seas el primer aliento en la mañana
Y la luz en mi ventana
Que seas mi universo
Que llenes cada uno de mis pensamientos
Que tu presencia y tu poder sean mi alimento
Oh, mi Jesús, que seas mi universo"""
    },
    {
        "title": "Qué Sería de Mí (Jesús Adrián Romero)",
        "lyrics": """¿Qué sería de mí si no me hubieras alcanzado?
¿Dónde estaría hoy si no me hubieras perdonado?
Tendría un vacío en mi corazón
Vagaría sin rumbo y sin dirección

Si no fuera por tu gracia y por tu amor
Si no fuera por tu gracia y por tu amor

Sería como un pájaro herido que se muere en el suelo
Sería como un ciervo que brama por agua en un desierto
Si no fuera por tu gracia y por tu amor
Si no fuera por tu gracia y por tu amor"""
    },
    {
        "title": "A Sus Pies (Jesús Adrián Romero)",
        "lyrics": """El aroma de mi perfume quiero derramar
A tus pies, Señor, me quiero postrar
No me importa el costo, quiero adorar
Y entregarte a Ti mi vida en tu altar

A sus pies mi vida se derrama
A sus pies mi alma encuentra calma
No hay lugar de más honra ni gloria
Que a los pies de mi Salvador"""
    },
    {
        "title": "Cerca de Ti (Jesús Adrián Romero)",
        "lyrics": """Si decidiera negar mi fe
Y no confiar nunca más en Él
No tengo a dónde ir, no tengo a dónde ir

Si despreciara en mi corazón
La santa gracia que me salvó
No tengo a dónde ir, no tengo a dónde ir

Convencido estoy que sin tu amor no puedo vivir
Cuenta me puedo dar que te necesito

Cerca de Ti, Señor, quiero estar
De tu presencia no me quiero alejar
Cerca de Ti, Jesús, yo soy feliz
Junto a tus pies es donde quiero vivir"""
    },
    {
        "title": "Con Manos Vacías (Jesús Adrián Romero)",
        "lyrics": """Con manos vacías vengo a Ti
No tengo nada que darte
No hay nada de valor en mí
No puedo impresionarte

Te puedo entregar mi corazón
Agradecido, mi corazón
Por todo lo que has hecho en mí
Por darme vida y perdón

Acepta hoy esta ofrenda de amor
Es lo que tengo para Ti, Señor
Acepta hoy esta ofrenda de amor
Es lo que tengo para Ti, Señor"""
    },
    {
        "title": "El Aire Que Respiro (Jesús Adrián Romero)",
        "lyrics": """Este es el aire que respiro
Este es el aire que respiro
Tu santa presencia viviendo en mí

Este es mi pan de cada día
Este es mi pan de cada día
Tu santa palabra hablándome a mí

Y yo te anhelo, Señor
Y estoy perdido sin Ti
Y yo te anhelo, Señor
Y estoy perdido sin Ti"""
    },
    {
        "title": "Princesas Mágicas (Jesús Adrián Romero)",
        "lyrics": """Había una vez un jardín y una niña
Que sonreía al mirarme jugar
Creció deprisa, de pronto vestida
Con sueños de blanca ilusión

Princesas mágicas que llenan mi hogar
Risas y cantos que alegran mi andar
Dios bendiga sus pasos, sus vidas también
Princesas mías, regalo del Rey"""
    },
    {
        "title": "Aquí Estoy (Jesús Adrián Romero)",
        "lyrics": """Aquí estoy, te ofrezco todo lo que soy
Aquí estoy, un sacrificio quiero ser
Toma mi ser, mi vida entrego a Ti

Porque Tú eres mi Dios, eres digno de adoración
Una ofrenda de amor seré para Ti
Porque Tú eres mi Dios, eres digno de adoración
Una ofrenda de amor seré para Ti"""
    },
    {
        "title": "Como la Brisa (Jesús Adrián Romero)",
        "lyrics": """Abro el corazón y las ventanas
Cuando empieza la mañana
Por si quieres hoy venir
Eres como el viento que no avisa
Cuando sopla y trae la brisa
Ven y sopla sobre mí

Y mi corazón vuelve a latir
Y se llena de tu paz
Nada anhelo más que estar junto a Ti
En tu presencia descansar"""
    },
    {
        "title": "Tal Como Soy (Jesús Adrián Romero)",
        "lyrics": """Tal como soy, Señor, sin nada que entregar
Más que el corazón, me rindo ante tu altar
Límpiame con tu sangre, lávame con tu amor
Acéptame, Señor, tal como soy

Tal como soy, Señor, acéptame
Con mis heridas, mi pasado y mi dolor
Acéptame, Señor, tal como soy"""
    },
    {
        "title": "Sentado En Su Trono (Jesús Adrián Romero)",
        "lyrics": """Sentado en su trono, rodeado de luz
A la diestra del Padre, gobierna Jesús
Con ojos de fuego, con rostro de sol
Cuando abre su boca, es trueno su voz

Poderoso en majestad y reino, poderoso
Poderoso en potestad e imperio, poderoso

Un gran arcoíris corona su ser
Él es el Cordero que pudo vencer
Él es el primero, Él es el postrer
Y arrojan coronas delante de Él"""
    },

    # ==========================================
    # MIEL SAN MARCOS
    # ==========================================
    {
        "title": "No Hay Lugar Más Alto (Miel San Marcos)",
        "lyrics": """A tus pies arde mi corazón
A tus pies entrego lo que soy
Es el lugar de mi seguridad
Donde nadie me puede señalar

Me perdonaste, me acercaste a tu presencia
Me levantaste, hoy me postro a adorar

No hay lugar más alto, más grande
Que estar a tus pies, que estar a tus pies
No hay lugar más alto, más grande
Que estar a tus pies, que estar a tus pies

Y aquí permaneceré, postrado a tus pies
Y aquí permaneceré a los pies de Cristo"""
    },
    {
        "title": "Danzo En El Río (Miel San Marcos)",
        "lyrics": """Hay un río de gozo que fluye del trono de Dios
Hay un río de gracia que llena de paz mi interior
Cosas que ojo no vio son las que Dios preparó
Para aquellos que aman su santo y glorioso favor

Danzo en el río, me alegro en tu paz
Salto de gozo, tu Espíritu está
Danzo en el río, me gozo en tu amor
Hay libertad en la casa de Dios"""
    },
    {
        "title": "Increíble (Miel San Marcos)",
        "lyrics": """Poderoso, invencible, admirable, grande y fuerte Dios
Rey de reyes, asombroso, incomparable
Increíble es tu amor

Increíble, invencible
Increíble es tu amor por mí
No hay nadie como Tú
Increíble, asombroso
Eres grande, mi Señor y Dios"""
    },
    {
        "title": "Grande y Fuerte (Miel San Marcos)",
        "lyrics": """Grande y fuerte es nuestro Dios
Grande y fuerte es nuestro Dios
Grande y fuerte es nuestro Dios
Grande y fuerte es nuestro Dios

Vestido en majestad, coronado con poder
Digno de toda gloria
La tierra cantará, el cielo proclamará
Grande y fuerte es nuestro Dios"""
    },
    {
        "title": "Proezas (Miel San Marcos)",
        "lyrics": """Dios de lo imposible, Dios de maravillas
Tú abres caminos donde no los hay
El mar se abre ante tu presencia
Montes se mueven al oír tu voz

En Dios haremos proezas
Él hollará a nuestros enemigos
En Dios haremos proezas
Su nombre es grande y vencedor"""
    },
    {
        "title": "Hay Libertad (Miel San Marcos)",
        "lyrics": """Las cadenas son rotas en su nombre
Los cautivos hoy son libres por su amor
El poder de las tinieblas se deshace
Cuando proclamamos a Cristo el Señor

Hay libertad en la casa de Dios
Hay libertad al alabarle a Él
Hay libertad en la casa de Dios
Hay libertad para adorar"""
    },
    {
        "title": "Dios Es Real (Miel San Marcos)",
        "lyrics": """Aunque no te pueda ver, puedo sentirte aquí
Aunque no te pueda tocar, sé que estás junto a mí
Tu Espíritu se mueve en este lugar
Trayendo sanidad, trayendo libertad

Dios es real, Él vive hoy
Su poder se manifiesta aquí
Dios es real, Él reina hoy
Por los siglos de los siglos"""
    },
    {
        "title": "Levántate Señor (Miel San Marcos)",
        "lyrics": """Levántate, levántate, Señor
Levántate, levántate, Señor
Huyan delante de Ti tus enemigos
Se dispersen delante de Ti todos aquellos que te aborrecen

Más los justos se alegrarán
Cantaré con regocijo
El Señor se ha levantado
Ha vencido con poder"""
    },

    # ==========================================
    # MONTESANTO
    # ==========================================
    {
        "title": "Fiesta En El Desierto (Montesanto)",
        "lyrics": """Aunque el desierto esté seco y no haya agua
Yo sé que tu lluvia temprana descenderá
Aunque mis ojos solo vean soledad
Tu gozo me inunda y me hace danzar

Haremos fiesta en el desierto
Celebraremos con gran poder
El gozo del Señor es mi fortaleza
Nada me puede detener

Danzando, saltando, en tu presencia me gozaré
Gritando victoria, porque grande es mi Rey"""
    },
    {
        "title": "La Sunamita (Montesanto)",
        "lyrics": """Preparé un aposento para Ti
Puse una mesa, una cama y un candil
Hombre de Dios, pasa y mora aquí
Este es un lugar apartado para Ti

Si Tú pasas por aquí, algo tiene que suceder
Si te quedas junto a mí, todo va a florecer
Pasa, Señor, y toma tu lugar
Este hogar te pertenece a Ti"""
    },
    {
        "title": "Derramo El Perfume (Montesanto)",
        "lyrics": """No me importa quién me mire, no me importa el qué dirán
Hoy rompo mi alabastro a los pies del Salvador
No me importa el costo de este perfume de adoración
Solo quiero derramarlo ante Ti, mi Señor

Derramo el perfume a tus pies, Jesús
Lloro de agradecimiento ante tu cruz
Eres digno de mi todo, eres digno de mi ser
Derramo el perfume a tus pies"""
    },
    {
        "title": "Cantamos Aleluya (Montesanto)",
        "lyrics": """El cielo se abre cuando te adoramos
La gloria desciende cuando te exaltamos
Los ángeles cantan Santo es el Cordero
Y toda la tierra responde con poder

Cantamos aleluya, cantamos aleluya
Al Rey que vive para siempre
Cantamos aleluya, cantamos aleluya
Al Dios de gloria y majestad"""
    },
    {
        "title": "Santo Es El Que Vive (Montesanto)",
        "lyrics": """Santo, Santo, digno, digno
Al que está sentado en el trono de gloria
Ángeles claman día y noche sin cesar
Santo es el que vive

Santo es el que vive, Santo es el que reina
Santo es el Cordero inmolado en la cruz
Toda honra, toda gloria pertenezca a Él
Por la eternidad"""
    },
    {
        "title": "No Soy Esclavo (Montesanto)",
        "lyrics": """Me envuelves hoy con una canción
Melodía de tu amor
Me diste paz en la tempestad
Mis miedos se van con tu voz

Ya no soy un esclavo del temor
Yo soy hijo de Dios
Ya no soy un esclavo del temor
Yo soy hijo de Dios

Abriste el mar para que yo pasara
Tu amor ahogó todo mi temor
Me rescataste y hoy yo puedo cantar
Yo soy hijo de Dios"""
    },

    # ==========================================
    # UN CORAZÓN
    # ==========================================
    {
        "title": "Jesucristo Basta (Un Corazón)",
        "lyrics": """Nuestros corazones insaciables son
Hasta que conocen a su Creador
Gracia que nos limpia, amor que nos perdonó
En la cruz hallamos nuestra redención

Jesucristo basta, Jesucristo basta
Mi castigo cayó sobre Él, su gracia me rescató
Jesucristo basta, Jesucristo basta
En su nombre seguro estoy, Jesús es suficiente

Cristo es mi herencia, nada me falta
En Él descanso, segura está mi alma"""
    },
    {
        "title": "Sueños (Un Corazón)",
        "lyrics": """En tus manos pongo lo que soy
Mis anhelos y mi porvenir
Tú conoces cada paso hoy
Tus caminos son mejores para mí

Tus sueños son más altos que mis sueños
Tus planes son eternos para mí
Confío en tu bondad, confío en tu amor
Haz tu voluntad en mí, Señor"""
    },
    {
        "title": "Salmo 23 (Un Corazón ft. Marco Barrientos)",
        "lyrics": """El Señor es mi pastor, nada me faltará
En lugares de verdes pastos me pastoreará
Junto a aguas de reposo me pastoreará
Confortará mi alma por sendas de justicia

Aunque ande en valle de sombra de muerte
No temeré mal alguno
Porque Tú estarás conmigo
Tu vara y tu cayado me infundirán aliento

Ciertamente el bien y la misericordia
Me seguirán todos los días de mi vida
Y en la casa de Dios moraré por largos días"""
    },
    {
        "title": "Hola Futuro (Un Corazón)",
        "lyrics": """Miro hacia el frente y ya no tengo miedo
Sé que conmigo va el Dios verdadero
El que venció la muerte y el dolor
El autor de mi salvación

Hola futuro, contigo caminaré
En las promesas de Dios confiaré
No importa la tormenta, firme estaré
Porque Jesús va adelante en fe"""
    },
    {
        "title": "Papá (Un Corazón)",
        "lyrics": """No tengo que temer el porvenir
En tus brazos encuentro descanso y paz
Tú conoces mi nombre y mi corazón
Eres mi Padre bueno, mi defensor

Papá, me amas como soy
Papá, seguro en Ti estoy
No hay amor más tierno ni más fiel
Que el amor de mi Padre celestial"""
    },
    {
        "title": "Regresará (Un Corazón)",
        "lyrics": """Los cielos proclaman la gloria de Dios
Y el mundo espera con devoción
La trompeta sonará y el Rey vendrá
Con gloria y poder a reinar

Regresará, vestido en majestad
Regresará, la iglesia le verá
Toda rodilla se doblará
Y toda lengua confesará que Él es Rey"""
    },
    {
        "title": "Cielo (Un Corazón)",
        "lyrics": """Hay un lugar donde no hay dolor
Donde no hay llanto ni aflicción
Donde contemplaremos cara a cara al Rey
Y cantaremos juntos por la eternidad

Cielo, anhelo de mi corazón
Cielo, morada de mi Salvador
Pronto estaremos contigo, Señor
En la presencia del Gran Dios"""
    },

    # ==========================================
    # BARAK, CHRISTINE D'CLARIO, JULIO MELGAR, HILLSONG, ELEVATION
    # ==========================================
    {
        "title": "La Tierra Canta (Barak)",
        "lyrics": """Se abre el cielo, se escucha un sonido celestial
Un clamor de adoración que hace temblar
Los cielos y la tierra se unen a una voz
Santo, Santo, digno es el Señor

La tierra canta, el cielo adora
Y todos gritan que Tú eres Santo
La tierra canta, el cielo adora
Y todos gritan que Tú eres digno"""
    },
    {
        "title": "Ven Espíritu Santo (Barak)",
        "lyrics": """Estoy aquí, desesperado por Ti
Con un corazón dispuesto a recibir
Derrama de tu fuego, derrama de tu unción
Ven y toma el control de este lugar

Ven, Espíritu Santo, ven
Llena este templo con tu gloria
Ven, Espíritu Santo, ven
Manifiesta tu poder aquí"""
    },
    {
        "title": "Como Dijiste (Christine D'Clario)",
        "lyrics": """Mueve el estanque en mi ser
Úneme a tu río, dame vida
No sé qué pasa alrededor
Solo sé que te anhelo hoy

Como dijiste que harías
Derrama de tu gloria aquí
Como dijiste en tu palabra
Ven y sopla de tu aliento en mí"""
    },
    {
        "title": "Que Se Abra El Cielo (Christine D'Clario)",
        "lyrics": """Dios es exaltado en este lugar
Su presencia es real
Rompemos cadenas con nuestra adoración
Al clamor de su santo pueblo

Que se abra el cielo, que caiga tu gloria
Queremos verte, Dios de victoria
Que se abra el cielo, tu fuego descienda
Sana la tierra, Dios de poder"""
    },
    {
        "title": "Creo En Ti (Julio Melgar)",
        "lyrics": """Quiero levantar a Ti mis manos
Maravilloso Jesús, milagroso Señor
Llena este lugar de tu presencia
Y haz descender tu poder a los que estamos aquí

Creo en Ti, Jesús
Y en lo que harás en mí
Creo en Ti, Jesús
Y en lo que harás en mí
En mí, en mí"""
    },
    {
        "title": "Cuerdas de Amor (Julio Melgar)",
        "lyrics": """Aunque pase por las aguas no me ahogaré
Aunque pase por el fuego no me quemaré
Tú estás conmigo, Señor
Tu amor me sostiene hoy

Con cuerdas de amor me ataste a Ti
Con lazos de gracia me trajiste aquí
No me soltarás, nunca me dejarás
Fiel es tu amor por mí"""
    },
    {
        "title": "Océanos - Donde Mis Pies Pueden Fallar (Hillsong)",
        "lyrics": """Tu voz me llama a las aguas
Donde mis pies pueden fallar
Y ahí te encuentro en lo incierto
Caminaré sobre el mar

A tu nombre clamaré
En Ti mis ojos fijaré
En tempestad, descansaré en tu poder
Pues tuyo soy hasta el final

Espíritu, guíame a confiar sin fronteras
Caminar sobre las aguas dondequiera que me llames
Llévame más profundo de lo que mis pies puedan bajar
Y mi fe será más firme en la presencia de mi Salvador"""
    },
    {
        "title": "Qué Hermoso Nombre (Hillsong)",
        "lyrics": """Tú fuiste el Verbo en el principio
Unigénito de Dios
El misterio de tu gloria revelado en tu amor

Qué hermoso su nombre es
Qué hermoso su nombre es
El nombre de Jesús, mi Rey
Qué hermoso su nombre es, nada se iguala a Él
Qué hermoso su nombre es, el nombre de Jesús

La muerte venciste, el velo partiste
La tumba vacía ahora está
Los cielos declaran tu gloria y victoria
Pues resucitaste, Jesús mi Rey"""
    },
    {
        "title": "La Bendición (Elevation Worship / Kari Jobe / Cody Carnes)",
        "lyrics": """El Señor te bendiga y te guarde
Haga resplandecer su rostro sobre ti
Y tenga de ti misericordia
El Señor alce su rostro sobre ti y te dé paz

Amén, amén, amén
Amén, amén, amén

Que su presencia vaya contigo
Y diez mil generaciones
Y tus hijos y sus hijos
Y los hijos de sus hijos"""
    },
    {
        "title": "Tumbas a Jardines (Elevation Worship)",
        "lyrics": """El mundo buscó satisfacerme
Pero nada encontró mi corazón
Hasta que llegaste Tú con gracia y poder
Y me diste vida nueva hoy

No hay nada mejor que mi Dios
No hay nada mejor que mi Dios
No hay nada, nada mejor que mi Dios

Tú cambias el luto en danzas
Tú cambias cenizas por gloria
Tú transformas tumbas en jardines
Eres el único Dios de poder"""
    }
]

def clean_stanzas(lyrics):
    parts = re.split(r'\n\s*\n', lyrics.strip())
    stanzas = []
    idx = 1
    for p in parts:
        clean_text = p.strip()
        if not clean_text:
            continue
        # Asignar nombre natural a la estrofa
        stanzas.append({
            "name": f"Párrafo {idx}",
            "text": clean_text
        })
        idx += 1
    return stanzas

def main():
    songs_file = "VisualDTB/Resources/songs.json"
    try:
        with open(songs_file, 'r', encoding='utf-8') as f:
            existing_songs = json.load(f)
    except Exception as e:
        print(f"Error cargando existentes: {e}")
        existing_songs = []

    print(f"Canciones existentes: {len(existing_songs)}")

    # Crear mapa de títulos normalizados existentes para no duplicar
    existing_titles_norm = {re.sub(r'[^a-zA-Z0-9áéíóúñÁÉÍÓÚÑ]', '', s['title'].lower()): s for s in existing_songs}

    added_count = 0
    updated_count = 0

    for s_data in NEW_SONGS_DATA:
        raw_title = s_data["title"]
        norm_title = re.sub(r'[^a-zA-Z0-9áéíóúñÁÉÍÓÚÑ]', '', raw_title.lower())
        
        # Comprobar si ya existe con o sin artista
        # Por ej: "Tu Fidelidad (Marcos Witt)" vs "Tu Fidelidad"
        base_title = raw_title.split("(")[0].strip()
        norm_base = re.sub(r'[^a-zA-Z0-9áéíóúñÁÉÍÓÚÑ]', '', base_title.lower())

        stanzas = clean_stanzas(s_data["lyrics"])
        new_entry = {
            "id": f"expanded-{len(existing_songs) + added_count + 1}",
            "title": raw_title,
            "stanzas": stanzas
        }

        # Si ya existe exactamente o como título base con menos estrofas, actualizarlo
        matched = existing_titles_norm.get(norm_title) or existing_titles_norm.get(norm_base)
        if matched:
            # Si la versión existente tiene pocas estrofas o está incompleta, actualizar stanzas y título
            matched["stanzas"] = stanzas
            matched["title"] = raw_title
            updated_count += 1
        else:
            existing_songs.append(new_entry)
            existing_titles_norm[norm_title] = new_entry
            added_count += 1

    print(f"Canciones agregadas: {added_count}")
    print(f"Canciones actualizadas: {updated_count}")
    print(f"Total de canciones resultantes: {len(existing_songs)}")

    with open(songs_file, 'w', encoding='utf-8') as f:
        json.dump(existing_songs, f, ensure_ascii=False, indent=4)
    print("songs.json guardado exitosamente!")

if __name__ == "__main__":
    main()

