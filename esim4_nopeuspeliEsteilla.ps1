#Vuoropohjainen liikkuminen 2D taulukossa
# kartta esimerkki: koordinaateilla.
#
#    0123456789 (x)
#   +----------+
# 0 |A         | <- Aloitus ekalla rivillä
# 1 |##### ####| <- joka toiselle riville esteitä
# 2 |          | <- joka toinen rivi tyhjää
# 3 |### ######| <- esteitä
# 4 |       ?  | <- Maali merkillä "?"
#(y)+----------+

#funktio jolla luodaan kartta leveyden ja korkeuden perusteella:
function luo_kartta([int]$leveys, [int]$korkeus,[string]$merkki="*") {
	$kartta=@()
	if ($leveys -gt 0 -and $korkeus -gt 0) {
		for($y=0;$y -lt $korkeus; $y++) {
			$rivi = @()
			for($x=0;$x -lt $leveys; $x++) {
				$rivi += $merkki
			}
			$kartta += , $rivi
		}
	}
	return $kartta
}

#funktio jolla luodaan karttaan esteitä silmukalla: (esteMerkki ja aukkoMerkki)
function luo_esteet([string]$eMerkki="#",[string]$aMerkki="*") {
	for ( $y=0; $y -lt $kartta.count; $y++) {
		#jos pariton, tehdään esterivi:
		if ( $y%2 -eq 1) 
		{
			for ( $x=0; $x -lt $kartta[$y].count; $x++ ) {
				#luodaan koko rivi esteitä:
				$kartta[$y][$x] = $eMerkki
			}
			#luodaan yksi aukko randomilla josta pääsee läpi:
			$aukko = get-random -min 0 -max $($kartta[$y].count -1)
			$kartta[$y][$aukko] = $aMerkki
		}
		
	}
}

#funktio, jolla piirretään pelin "sykleissä" kartta näytölle
function naytakartta {
	#tulostetaan kartta kuten yllä pohdittu... käytetään kahta for-lausetta:
	
	for ( $y = 0; $y -lt $kartta.count; $y++ ) {
		$rivi = ""
		for ( $x = 0; $x -lt $kartta[$y].count; $x++ ) {
			$rivi += $kartta[$y][$x]
		}
		write-host "$rivi" -foreground darkgreen
	}
	

	#kertoo pisteet:
	#write-host $($hahmo.Nimi+", Pisteet: "+$hahmo.pisteet) -foreground yellow
	
	#kertoo missä olet:
	write-host $("Olet koordinaatissa: ("+$hahmo.x+","+$hahmo.y+")") -foreground cyan

	#Käytetään välilyönnin kanssa:
	write-host "$toimintoteksti`n$virheet" -foreground cyan
}

#hahmon liikkuminen (palauttaa false jos peli on ohi, muutoin true)
function siirry([int]$x,[int]$y) {

	$palautus = $true
	
	#kopsataan arvot testiä varten:
	[int]$testiX = $hahmo.x
	[int]$testiY = $hahmo.y
	
	#luodaan uudet koordinaatit:
	$testiX=$testiX+$x
	$testiY=$testiY+$y
	
	#Nollataan pelaajan sijainti kartalla, ettei piirretä useita hahmoja:
	$kartta[$hahmo.y][$hahmo.x] = "*"	
	
	#reunatunnistus: eli jos uus koordinaatto on pienempi kuin vasen reuna tai suurempi kuin oikea reuna, ollaan menty yli kartan, ei siis siirretä:
	if ( $testiX -lt $VasenReuna -or $testiX -gt $OikeaReuna ) {
		#ei siirretä koska testaus menee yli rajojen
	}
	#muutoin voidaan siirtää
	else {
		
		#Tarkistetaan vielä, että ei vaan ole este:
		if ( $kartta[$testiY][$testiX] -ne "#" ) {
		
			#lisätään maalia varten tarkastelu, jossei maali, niin siirretään:
			if ( $kartta[$testiY][$testiX] -eq "?") {
				#palautetaan "pelataan"-muuttujalle arvo "ei enää"
				$palautus = $false
			}
			else {
				#annetaan uus arvo X akselilla
				$hahmo.x = $testiX
			}
		}
		
	}
	#reunatunnistus osa 2: jos ollaan menty yläreunan yli (y < 0) tai (y > Alareuna) ollaan menty yli kartan taas, ei saa siirtää:
	if ( $testiY -lt $YlaReuna -or $testiY -gt $AlaReuna ) {
		#ei siirretä koska testaus menee yli rajojen
	}
	#muutoin voidaan siirtää
	else {
		#Tarkistetaan vielä, että ei vaan ole este:
		if ( $kartta[$testiY][$testiX] -ne "#" ) {
			#lisätään maalia varten tarkastelu, jossei maali, niin siirretään:
			if ( $kartta[$testiY][$testiX] -eq "?") {
				#palautetaan "pelataan"-muuttujalle arvo "ei enää"
				$palautus = $false
			}
			else {
				#annetaan uus arvo X akselilla
				$hahmo.y = $testiY
			}
		}
	}
		
	#sijoitetaan hahmo mahdolliseen uuteen paikkaan kartalle:
	$kartta[$hahmo.y][$hahmo.x] = $hahmo.karttamerkki
	
	return $palautus
	
}
# välilyönnin testifunktio
function tutki_alue {
	$pisteet = get-random -min 1 -max 3
	if ( $pisteet -eq 1) {
		$teksti = "Tutkit alueen, mutta et löytänyt mitään"
	} else {
		$teksti = "Tutkit alueen ja löysit kolikon!"
		$hahmo.pisteet+=1
	}
	return $teksti
}

#pelin "suorituslohko:"
function aloita_peli {
	#cls
	write-host "Tervetuloa pelaamaan karttaseikkailua!" -foreground darkgreen
	#Kysytään nimi:
	$hahmo.nimi = read-host "Anna pelaajan nimi"
	
	$pelataan = $true
	$aloitusAika = get-date
	while ($pelataan -eq $true) {

		#tyhjennetään ruutu ja tulostetaan kartta:
		cls
		naytakartta
		
		#luetaan joka syklissä näppäimen painallus (peli odottaa näppistä tässä):
		$painike = $host.UI.RawUI.ReadKey("NoEcho,IncludekeyDown")

		#jos halutaan pysäyttää peli:
		if ( $painike.VirtualKeyCode -eq 27) {
			$pelataan = $false
		}
		#37 = vasen
		elseif ( $painike.VirtualKeyCode -eq 37) {
			#write-host "siirrä x-1"
			$pelataan = siirry -x -1 -y 0
			$toimintoteksti=""
		}
		#38 = ylös
		elseif ( $painike.VirtualKeyCode -eq 38) {
			#write-host "siirrä y-1"
			$pelataan = siirry -x 0 -y -1
			$toimintoteksti=""
		}
		#39 = oikea
		elseif ( $painike.VirtualKeyCode -eq 39) {
			#write-host "siirrä x+1"
			$pelataan = siirry -x 1 -y 0
			$toimintoteksti=""
		}
		#40 = alas
		elseif ( $painike.VirtualKeyCode -eq 40) {
			#write-host "siirrä y+1"
			$pelataan = siirry -x 0 -y 1
			$toimintoteksti=""
		}
		#32 = välilyönti
		elseif ( $painike.VirtualKeyCode -eq 32) {
			#toiminnallisuus:
			$toimintoteksti=$(tutki_alue)
		}
		else {
			$toimintoteksti="Virheellinen painike: nuolet ja välilyönti sallittuja.`nja ESC lopettaa pelin"
		}
		
	}
	#Tänne päästään kun peli sykli on päättynyt
	
	#Otetaan lopetusaika ylös:
	$lopetusAika = get-date
	#lasketaan erotus:
	$kesto = $lopetusAika - $aloitusAika
	#Tulostetaan kuluneet sekunit:
	write-host "Peli päättyi! Maaliin pääsit $($kesto.Seconds) sekunnissa"
	
	
	
}




#ALKUMÄÄRITTELYT ALKAVAT TÄSTÄ:

#luodaan pelaajan hahmo objekti:
$hahmo = new-object PSObject -Property @{
"Nimi"="";
"x"=0;
"y"=0;
"karttamerkki"="A"
}

#Käytetään tätä läpikulkemattomana objektina:
$esteMerkki = "#"
#Käytetään tätä "kävelyalueen merkkinä"
$kulkuMerkki = "*"
#Käytetään tätä merkkiä kohteena johon pääsemällä peli päättyy:
$maaliMerkki = "?"

#Luodaan funktiolla 20x10 kokonen kartta:
$kartta = luo_kartta -leveys 20 -korkeus 11

#luodaan myös esteet:
luo_esteet -eMerkki $esteMerkki -aMerkki $kulkuMerkki

#Nimetään kartan reunat ehtolausetestailuja varten:
$VasenReuna = 0
$OikeaReuna = $kartta[0].count -1
$YlaReuna = 0
$AlaReuna = $kartta.count -1

#sijoitetaan hahmo kartalle ekaa kertaa:
$kartta[$hahmo.y][$hahmo.x] = $hahmo.karttamerkki

#luodaan vielä lopuksi maali:
$MaaliSijainti = get-random -min 0 -max $OikeaReuna
$kartta[$AlaReuna][$MaaliSijainti] = $maaliMerkki

#Käynnistetään peli:
aloita_peli
