#!/bin/bash

# HERRAMIENTAS

trap ctrl_c INT      # AQUI PONER QUE SI ES QUE NO TENIAS INSTALADO PREVIAMENTE DIALOG SE TE DESINTALE AUTOMATICAMENTE, SI YA LO TENIAS ANTES ENTONCES QUE NO DESINTALE NADA
function ctrl_c(){
	rm resp.txt > /dev/null 2>&1
	rm tmp* > /dev/null 2>&1
	if [ "$instalaci" == "no" ]; then
		apt-get remove dialog -y > /dev/null 2>&1
	fi
	clear
        echo -e "\n${redColour}[!] Saliendo...\n${endColour}"
	exit
}

#tabulador

function tabulador(){
        # Parametros
        delin="$1"
        texto="$(cat $2)"
        textosin="$(echo "$texto" | sed "s/$delin/ /g")"

        # TABLATOTAL

                turno="$(echo "$textosin" | head -n 1 | wc -w )"
                vueltas=1
                while true; do
                        if [ $vueltas -le $turno ]; then
                                for i in "$textosin"; do
                                        echo "$i" | awk "{print \$$vueltas}" >> primlin.table
                                done
                                lin="$(cat primlin.table | wc -L)"
                                while IFS= read -r line; do
                                        while true; do
                                                num="$(echo "$line" | wc -m)"
                                                if [[ "$num" -le "$lin" ]]; then
                                                        line="$(echo "$line" | awk '{print $0" "}')"
                                                else
                                                        echo "| $line" | awk '{print $0" |"}' >> page$vueltas.txt
                                                        break
                                                fi
                                        done
                                done < primlin.table
                                rm primlin.table
                                vueltas=$(($vueltas + 1))
                        else
                                paste -d' ' $(ls | grep "page") > fin.table
                                lin="$(cat fin.table | wc -L)"
                                sed -i '2i+' fin.table
                                while true; do
                                        num="$(cat fin.table | awk 'NR==2' | wc -m)"
                                        if [[ "$num" -lt "$lin" ]]; then
                                                sed -i '2s/$/-/' fin.table
                                        else
                                                sed -i '2s/$/+/' fin.table
                                                tod="$(cat fin.table | awk 'NR==2')"
                                                echo $tod >> fin.table
                                                sed -i "1i$tod" fin.table
                                                break
                                        fi
                                done
                                sleep 3
                                cat fin.table
                                rm fin.table
                                rm page*
                                break
                        fi
                done
}

#colores
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turqColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"


# CODIGO

function quitarAct(){
 	clear
	rt="$(cat datos.txt)"
	mn="$(cat datos.txt | wc -l)"
	((mn=$mn-1))
	rt="$(echo "$rt" | tail -n $mn | wc -l)"
	if [ $rt == 0 ]; then
		dialog --title "Rutina" \
			--msgbox "\nNo cuanta con ninguna actividad para eliminar" 0 0
		pasos
	else
		dts="$(cat datos.txt | tr "-" " " | awk '{print $1}')"
        	num="$(cat datos.txt | wc -l)"
        	((num=$num-1))
        	dts="$(echo "$dts" | tail -n $num)"
        	for ((tl=1; tl < $num; tl++)); do
               		txt="$(echo "$dts" | awk "NR==$tl")"
                	echo $tl $txt "off\\" >> dts.rt
        	done
        	txt="$(echo "$dts" | awk "NR==$tl")"
        	echo $tl $txt "on" >> dts.rt
        	dts="$(cat dts.rt)"
        	rm dts.rt
        	resp=$(dialog --title "Rutina" \
        	        --stdout \
        	        --checklist "Cuales desea eliminar?" 0 0 3 \
        	                $dts)
		val="$(echo $resp | wc -w)"
        	resp="$(echo $resp | rev)"
		dialog --title "Rutina" \
			--yesno "\nSeguro que desea elimar la actividad\n" 0 0
		rep=$?
		if [ $rep == 1 ]; then
			quitarAct
		else
			for ((tl=1; tl <= $val; tl++)); do
        	        	num=$(echo $resp | awk "{print \$$tl}")
				((num=$num+1))
        	        	sed -i "$num d" datos.txt
        		done
			pasos
		fi
	fi
}

function agregarAct(){
	while true; do
                dialog --title "Rutina" \
                        --inputbox "\nRecuerda no utilizar \"_\" y \"-\"\nMax. Caracteres en el texto \"35\"\n\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n$tst\n\nActividad:" 0 0 2> $arch"tst.txt"
                rs=$?
                txt="$(cat $arch"tst.txt")"
		nm="$(echo "$txt" | wc -m)"
		((nm=$nm-1))
                if [ $rs == 1 ] || [ $rs == 255 ]; then
                        if [ -z "$tst" ]; then
				pasos
			else
				loading
			fi
                else
                        if [ -z "$txt" ]; then
                                dialog --title "Rutina" \
                                        --msgbox "\nFavor de poner un texto valido" 0 0
                        elif [[ "$txt" == *"_"* ]] || [[ "$txt" == *"-"* ]]; then
                                dialog --title "Rutina" \
                                        --msgbox "\nFavor de no utilizar \"-\" o \"_\" en el texto" 0 0
			elif [[ "$nm" -gt "35" ]]; then
				dialog --title "Rutina" \
                                        --msgbox "\nFavor de no utilizar mas de \"35 caracteres\"\n\nUsted cuenta con: $nm caracteres" 0 0
			else
                                txtone="$txt"
				while true; do
					rep=$(dialog --title "Rutina" \
                   					--stdout \
                   					--calendar "\n$tst2\n\nFecha a agendar:" 0 0)
					rs=$?
					txttwo=$rep
					if [ $rs == 1 ] || [ $rs == 255 ]; then
						break
					else
						while true; do
							resp=$(dialog --title "Rutina" \
									--stdout \
									--timebox "\n$tst3\n\nHora a agendar:" 0 0)
							rs=$?
							txtre=$resp
							if [ $rs == 1 ] || [ $rs == 255 ]; then
								break
							else
								while true; do
									dialog --title "Rutina" \
										--inputbox "\nRecuerda no utilizar \"_\" y \"-\"\nMax. Caracteres en el texto \"15\"\n\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n$tst4\n\nAnotacion:" 0 0 2> $arch"tst.txt"
									rs=$?
									txt="$(cat $arch"tst.txt")"
									nm="$(echo "$txt" | wc -m)"
									if [ $rs == 1 ] || [ $rs == 255 ]; then
										break
									else
										if [ -z "$txt" ]; then
											dialog --title "Rutina" \
                                        							--msgbox "\nFavor de poner un texto valido" 0 0
										elif [[ "$txt" == *"_"* ]] || [[ "$txt" == *"-"* ]]; then
											dialog --title "Rutina" \
												--msgbox "\nFavor de no utilizar \"-\" o \"_\" en el texto" 0 0
										elif [[ "$nm" -gt "15" ]]; then
                                							dialog --title "Rutina" \
                                       								--msgbox "\nFavor de no utilizar mas de \"15 caracteres\"\n\nUsted cuenta con: $nm caracteres" 0 0
										else
											txtfor=$txt
											dialog --title "Rutina" \
												--yesno "\nSeguro que quiere agregar lo siguiente?$tstFinal\n\n~~~~~~~~~~~~~~~\n\nActividad:$txtone\nFecha:$txttwo\nHora:$txtre\nAnotacion:$txtfor" 0 0
											rs=$?
											if [ $rs == 1 ] || [ $rs == 255 ]; then
												echo ""
											else
												txtone="$(echo $txtone | tr " " "_")"
        											txtre="$(echo $txtre | cut -c -5)"
      												txtfor="$(echo $txtfor | tr " " "_")"
        											full="$(echo $txtone"-"$txttwo"_"$txtre"-"$txtfor)"
        											echo $full >> datos.txt
												if [ -z "$tst" ]; then
													dialog --title "Rutina" \
                                                                                                        	--msgbox "\nRegresara al menu" 0 0
													pasos
												else
													dialog --title "Rutina" \
														--msgbox "\nRegresara al editor" 0 0
												fi
												break 4
											fi
										fi
									fi
								done
							fi
						done
					fi
				done
			fi
                fi
        done
}

function loading(){
	carga &
	dat="$(jobs -l | grep "carga &" | awk '{print $2}')"
	editar
}

function editar(){
	xt="$(cat datos.txt | wc -l)"
        if [  $xt == 2 ]; then
		sleep 3
		kill "$dat"
		dialog --title "Rutina" \
			--msgbox "Se editara la unica rutina que cuenta" 0 0
		val=1
	else
		datos="$(tabulador "-" "datos.txt")"
		datos="$(echo -e "$datos" | tr " " "~" | sed 's/|~|/| |/g' )"
		echo "$datos" > tmp.txt
		while IFS= read -r lin; do
			echo $lin"\n" >> tmp2.txt
		done < tmp.txt
		datos=$(cat tmp2.txt) 2>/dev/null
		rm tmp* 2>/dev/null
		lh="$(cat datos.txt | wc -l)"
		((lh=$lh-1))
		txt="$(cat datos.txt | tail -n $lh)"
		echo "$txt" | tr "-" " " | awk '{print $1}' > tmp.txt
		vuelta=1
		while IFS= read -r lin; do
			echo $vuelta" \""$lin"\"\\" >> tmp2.txt
			((vuelta=$vuelta+1))
		done < tmp.txt
		echo $vuelta" \"Regresar\"" >> tmp2.txt
		texto="$(cat tmp2.txt)" 2>/dev/null
		rm tmp* 2>/dev/null
		kill "$dat"
		dialog --title "Rutina" \
			--menu "\nFavor de seleccionar la rutina a editar\n\n$datos\n\n" 0 0 0 \
				$texto 2> resp.txt
		val="$(cat resp.txt)" 2>/dev/null
		rm resp.txt 2>/dev/null
		if [ -z "$val" ]; then
			pasos
		fi
		((lh=$lh+1))
		case $val in
			$lh)
				pasos
				;;
		esac
								#text="$(cat tmp.txt)" 2>/dev/null
								#rm tmp.txt 2>/dev/null
	fi
	((val=$val+1))
	del="$(cat datos.txt | awk "NR==$val")"
	val=$val"d"
	del="$(echo $del | tr '-' ' ')"
	tst="Datos editando: $(echo $del | awk '{print $1}')"
	tst2="Datos editando: $(echo $del | awk '{print $2}' | tr '_' ' ' | awk '{print $1}')"
	tst3="Datos editando: $(echo $del | awk '{print $2}' | tr '_' ' ' | awk '{print $2}')"
	tst4="Datos editando: $(echo $del | awk '{print $3}')"
	tsst="$(echo $del | awk '{print $1}')"
        tsst2="$(echo $del | awk '{print $2}' | tr '_' ' ' | awk '{print $1}')"
        tsst3="$(echo $del | awk '{print $2}' | tr '_' ' ' | awk '{print $2}')"
        tsst4="$(echo $del | awk '{print $3}')"
	tstFinal="\n\nActividad editando:\n\n~~~~~~~~~~~~~~~\n\nActividad:$tsst\nFecha:$tsst2\nHora:$tsst3\nAnotacion:$tsst4\n\nDatos cambiados: "
	agregarAct
	sed -i $val datos.txt
	loading
}

function instalacion(){
	depe="dialog"
	re="$(which $depe)"
	if [[ "$re" == *"/"* ]]; then
		instalaci="si"
	else
		sleep 2
		if [ "$(id -u)" == "0" ]; then
			kill "$dat"
			while true; do
				echo -e "\n\n${yellowColour}Si esta de acuerdo se instalara automaticamente la\ndependencia necesaria\n\"$depe\"\n\nO lo puede instalar manualmente\n'sudo apt install dialog'${endColour}"
				echo -e "\n\n[y/n]"
				read rpp
				case $rpp in
					y)
						carga &
						dat="$(jobs -l | grep "carga &" | awk '{print $2}')"
						apt-get install $depe -y > /dev/null 2>&1
						break
						;;
  					n)
			    			ctrl_c
						;;
					*)
						echo -e "\nFavor de poner una respuesta valida..."
						echo "Presione cualquier tecla para continuar"
						read l
						clear
						;;
				esac
			done
			re="$(which $depe)"
			if [[ "$re" == *"/"* ]]; then
                        	echo ""
                	else
				echo -e "\n\n\n${redColour}Algo fallo en la instalacion de la dependencia, Que cosa???, NO SE >;D${endColour}"
                	fi
                else
			echo -e "\n\n${yellowColour}Favor de ingresar como root para instalar la\ndependencia necesaria \n\"$depe\"\n\nO lo puede instalar manualmente\n'sudo apt install dialog'${endColour}"
                	read l
		fi
		instalaci="no"
		clear
	fi
}

function pasos(){
	carga &
	arch="$(mktemp -d)"
	dat="$(jobs -l | grep "carga &" | awk '{print $2}')"
	instalacion
	datos
}

function datos(){
        xt="$(cat datos.txt | wc -l)"
        if [  $xt == 1 ]; then
		sleep 4
                kill "$dat"
                dialog --title "Rutina" \
                        --msgbox "\nNo cuanta con ninguna actividad, Pasara directamente a \"Agregar Actividad\"" 0 0
                agregarAct
        else
                datos="$(tabulador "-" "datos.txt")"
                datos="$(echo -e "$datos" | tr " " "~" | sed 's/|~|/| |/g' )"
        	echo "$datos" > tmp.txt
                while IFS= read -r lin; do
                        echo $lin"\n" >> tmp2.txt
                done < tmp.txt
                datos=$(cat tmp2.txt)
                rm tmp*
	        kill "$dat"
		dialog --title "Rutina" \
                        --menu "\nFavor de elegir la opcion preferida\n$datos" 0 0 0 \
                                1 "Agregar Actividad" \
                                2 "Quitar Actividad" \
                                3 "Editar Actividad" \
                                4 "Salir" 2> resp.txt
                resp=$(cat resp.txt)
                rm resp.txt
                case $resp in
                        1)
                                agregarAct
                                ;;
                        2)
                                quitarAct
                                ;;
                        3)
                                loading
                                ;;
                        *)
                                clear
                                ctrl_c
                                ;;
		esac
        fi
}

function carga(){
	for i in $(seq 0 25 100); do
		sleep 1
		echo $i | dialog --title "La motivacion a unos clicks" \
			--gauge "\nEspera hasta que termine por favor" 0 0 0
	done
}

#instalacion
pasos

