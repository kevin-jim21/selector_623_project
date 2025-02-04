;*******************************************************************************
;                          PROYECTO SELECTOR 623
;*******************************************************************************
; Versión: 1
; Autor: Kevin Jimenez Acuna
; Fecha: 9 de diciembre, 2024
; --------------------------- Documentación ------------------------------------
; Explicación del problema: se desea desarrollar una aplicación para una máquina
; que tenga la capacidad de estimar la longitud de las barras de aluminio bruto
; producidas por una empresa siderúrgica y a su vez, poder demarcar las barras
; que cumplen con los parámetros de longitud adecuados. Para ello se propone
; la implementación del Selector 623, consiste en una máquina con tres modos
; de operación, en donde el modo Seleccionar permite medir barras de aluminio a
; partir de dos sensores ultrasónicos que emiten pulsos cuando detectan y dejan
; de detectar las barras de aluminio y también, un rociador que marca las barras
; de aluminio que cumplen con el rango de longitud programado. De esta forma,
; las barras se colocan sobre una cinta que viaja por debajo de los sensores
; ultrasónicos y finalmente llegan al rociador.
;
; TAREAS Y SUBRTUINAS:
;
; i)Tarea_Modo_Stop
; ii) Tarea_Configurar
; iii) Tarea_Modo_Seleccionar
; iv) Tarea_Brillo
; v) Tarea_Teclado
; vi) Tarea_Led_Testigo
; vii) Tarea_Leer_PB1
; viii) Tarea_Leer_PB2
; ix) Tarea_Leer_DS
; x) Tarea_PantallaMUX
; xi) Tarea_LCD
; xii) Send_LCD
; xiii) Subrutina BCD_BIN
; xiv) Subrutina Calcula
; xv) Subrutina BIN_BCD_MUXP
; xvi) Subrutina BCD_7Seg
; xvii) Subrutina Borrar_Num_Array
; xviii) Subrutina Leer_Teclado
; xix) Máquina de tiempos
;*******************************************************************************
#include registers.inc
;*******************************************************************************
;                 RELOCALIZACION DE VECTOR DE INTERRUPCION
;*******************************************************************************
                                Org $3e66
                        dw Maquina_Tiempos
;*******************************************************************************
;                          DEFINICION DE VALORES
;*******************************************************************************
;--------------------------- Tarea Teclado -------------------------------------
tSuprRebTCL:                        EQU 10
;-------------------------- Tarea PantallaMUX ----------------------------------
tTimerDigito:                    EQU 2
MaxCountTicks:                       EQU 100
;--------------------------- Tarea LCD -----------------------------------------
tTimer2mS:                       EQU 2
tTimer260uS:                    EQU 13
tTimer40uS:                      EQU 2
EOB:                            EQU $FF
Clear_LCD:                      EQU $01
ADD_L1:                         EQU $80
ADD_L2:                         EQU $C0
;--------------------- Tarea LeerPB1 y LeerPB2 ---------------------------------
PortPB:                         EQU PTIH
MaskPB1:                         EQU $08
MaskPB2:                           EQU $01
tSupRebPB:                          EQU 10
tShortP:                        EQU 30
tLongP:                             EQU 3
;--------------------------- Tarea Configurar ----------------------------------
LDConfig:                       EQU $01
Lmin:                           EQU 70
Lmax:                           EQU 99
;------------------------------- Tarea Stop ------------------------------------
LDStop:                                 EQU $04
;--------------------------- Tarea Seleccionar ---------------------------------
LDSelect:                       EQU $02
tTimerCal:                      EQU 100                  ; 10S
tTimerError:                    EQU 20                  ; 2S
tTimerShot:                     EQU 2                   ; 200 mS
VelocMin:                       EQU 10
VelocMax:                       EQU 50
DeltaX_S:                       EQU 50
DeltaX_R:                       EQU 150
;------------------------------ Tarea Brillo -----------------------------------
tTimerBrillo:                   EQU 4                   ; 400 mS
MaskSCF:                        EQU $80
;----------------------------- Tarea Leer DS -----------------------------------
tTimerRebDS:                    EQU 80
;----------------------------- Banderas  ---------------------------------------
ShortP1:                          EQU $01
LongP1:                           EQU $02
ShortP2:                          EQU $04
LongP2:                           EQU $08
Array_OK:                         EQU $10
RS:                               EQU $01
LCD_Ok:                           EQU $02
FinSendLCD:                       EQU $04
Second_Line:                      EQU $08
;----------------------------- Generales  --------------------------------------
tTimerLDTst:                      EQU 5
Carga_TC4:                      EQU 120 ; Incluir en progprincipal y maqtiempos
;--------------------------- Tabla Timers --------------------------------------
tTimer1mS:                        EQU 50
tTimer10mS:                       EQU 500
tTimer100mS:                     EQU 5000
tTimer1S:                         EQU 50000
;*******************************************************************************
;                  DECLARACION DE LAS ESTRUCTURAS DE DATOS
;*******************************************************************************
;---------------------------- TAREA_TECLADO  -----------------------------------
                                     Org $1000
MAX_TCL:                          dB 2
Tecla:                            dB $FF
Tecla_IN:                         dB $FF
Cont_TCL:                         dB 0
Patron:                           dB 0
Est_Pres_TCL:                     ds 2
                                     Org $1010
Num_Array:                        dB $FF,$FF
;------------------------ TAREA_PANTALLAMUX  -----------------------------------
                                    Org $1020
EstPres_PantallaMUX:            ds 2
Dsp1:                           ds 1
Dsp2:                           ds 1
Dsp3:                           ds 1
Dsp4:                           ds 1
LEDS:                           ds 1
Cont_Dig:                       ds 1
Brillo:                         ds 1
;------------------------- SUBRUTINAS DE CONVERSION ----------------------------
BCD:                            ds 1
Cont_BCD:                       ds 1
BCD1:                           ds 1
BCD2:                           ds 1
;---------------------------- TAREA LCD  ---------------------------------------
IniDsp:                         dB $28,$28,$06,$0C,$FF
Punt_LCD:                       ds 2
CharLCD:                        ds 1
Msg_L1:                         ds 2
Msg_L2:                         ds 2
EstPres_SendLCD:                ds 2
EstPres_TareaLCD:               ds 2
;---------------------- TAREA LEERPB1 Y LEERPB2 --------------------------------
EstPres_LeerPB1:                  ds 2
EstPres_LeerPB2:                 ds 2
;-------------------------- TAREA CONFIGURAR -----------------------------------
Est_Pres_TConfig:                  ds 2
ValorLong:                      ds 1
LongOK:                        ds 1
;-------------------------- TAREA SELECCIONAR ----------------------------------
Est_Pres_TSelec:                  ds 2
Longitud:                       ds 1
DeltaT:                         ds 1
Velocidad:                      ds 1
;---------------------------- TAREA BRILLO -------------------------------------
Est_Pres_TBrillo:               ds 2
;---------------------------- TAREA LEER DS ------------------------------------
Est_Pres_LeerDS:                ds 2
Temp_DS:                        ds 1
Valor_DS:                       ds 1
;------------------------------ BANDERAS ---------------------------------------
                                   Org $1070
Banderas_1:                     ds 1
Banderas_2:                     ds 1
;------------------------------ GENERALES  -------------------------------------
                                   Org $1080
Est_Pres_LDTst:                         ds 2
;-------------------------------------------------------------------------------
LD_Red:                         EQU $10         ; Mascaras LED tricolor
LD_Green:                       EQU $20
LD_Blue:                        EQU $40
;------------------------------ TABLAS -----------------------------------------
                                    Org $1100
Segment:        dB $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F,$40,$00
                                Org $1110
Teclas:         dB $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$00,$0E
;------------------------------- MENSAJES --------------------------------------
                                    Org $1200
Msg_powerupreset:                       FCC "  uProcesadores "
                                dB $FF
Msg_Bienvenida:                         FCC "  SELECTOR 623  "
                                dB $FF
Msg_Stop:                               FCC "    MODO STOP   "
                                dB $FF
Msg_Config1:                            FCC "MODO  CONFIGURAR"
                                dB $FF
Msg_Config2:                            FCC "INGRESE   LongOK"
                                dB $FF
Msg_Seleccionar:                        FCC "MODO SELECCIONAR"
                                dB $FF
Msg_EsperandoS1:                        FCC " ESPERANDO S1..."
                                dB $FF
Msg_EsperandoS2:                        FCC " ESPERANDO S2..."
                                dB $FF
Msg_Espera_FinBarra:                    FCC "ESPERA FIN BARRA"
                                dB $FF
Msg_Calculando:                         FCC " CALCULANDO ... "
                                dB $FF
Msg_Resultados:                         FCC "VELOC       LONG"
                                dB $FF
Msg_Alerta_Velocidad:                   FCC "** VELOCIDAD ** "
                                dB $FF
Msg_Alerta_Longitud:                           FCC " ** LONGITUD ** "
                                dB $FF
Msg_Alerta_FueraRango:                  FCC "*FUERA DE RANGO*"
                                dB $FF
;-------------------------- TABLA DE TIMERS ------------------------------------
                                   Org $1500
Tabla_Timers_BaseT:

Timer1mS:                       ds 2
Timer10mS:                      ds 2
Timer100mS:                     ds 2
Timer1S:                        ds 2
Counter_Ticks:                  ds 2
Timer260uS:                     ds 2
Timer40uS:                      ds 2
Fin_BaseT                       dW $FFFF

Tabla_Timers_Base1mS

Timer_RebPB1:                     ds 1
Timer_RebPB2:                     ds 1
Timer_RebTCL:                    ds 1
Timer_RebDS:                    ds 1
TimerDigito:                    ds 1
Timer2mS:                         ds 1
Fin_Base1mS:                    dB $FF

Tabla_Timers_Base10mS

Timer_SHP1:                       ds 1
Timer_SHP2:                       ds 1
Fin_Base10                       dB $FF

Tabla_Timers_Base100mS

TimerCal:                       ds 1
TimerError:                     ds 1
TimerPant:                      ds 1
TimerFinPant:                   ds 1
TimerRociador:                  ds 1
TimerShot:                      ds 1
TimerBrillo:                    ds 1
Timer_LED_Testigo:              ds 1
Fin_Base100                     dB $FF

Tabla_Timers_Base1S

Timer_LP1:                        ds 1
Timer_LP2:                        ds 1
Fin_Base1S                        dB $FF
;===============================================================================
;                        CONFIGURACION DE PERIFÉRICOS
;===============================================================================
                        Org $2000

        Bset DDRB,$FF     ;HabilitacionLEDS
        Bset DDRJ,$02
        Bset DDRE,$04     ; Utilizar Relé
        
        Movb #$0F,PTP   ; Sensores S1 y S2 (botones)

        Movb #$FF,DDRP    ; Habilitar led tricolor y displays 7 seg
        Bset PUCR,$01     ; Habilitacion resitencia PULL-UP PORTA
        Movb #$F0,DDRA    ;Habilitacion de Teclado Matricial
        
                Movb #$C0,ATD0CTL2      ; Configurar ATD
                Ldaa #160
init_ATD        Dbne A,init_ATD
                Movb #$20,ATD0CTL3
                Movb #$84,ATD0CTL4              ; 8 BITS ACTIVADO
                Movb #$87,ATD0CTL5

        Movb #$90,TSCR1
        Movb #$02,TSCR2
        Movb #$10,TIOS
        Movb #$10,TIE
        
;===============================================================================
;                    INICIALIZACIÓN ESTRUCTURAS DE DATOS
;===============================================================================
        
        Movb #tTimerLDTst,Timer_LED_Testigo  ; Inicia timer parpadeo led testigo
        Movw #MaxCountTicks,Counter_Ticks
        Movw #tTimer1mS,Timer1mS
        Movw #tTimer10mS,Timer10mS        ; Inicia los timers de bases de tiempo
        Movw #tTimer100mS,Timer100mS
        Movw #tTimer1S,Timer1S

        Ldd TCNT        ; Frecuencia en el canal 4
        Addd #Carga_TC4
        Std TC4
        
;-------------------------------------------------------------------------------
        Movw #SendLCD_Est1,EstPres_SendLCD        ; Necesario para init_LCD
        Lds #$3BFF
        Cli
;------------------- Inicializacion LCD ----------------------------------------
                Movw #tTimer40uS,Timer40uS      ; Incializar timers
                Movw #tTimer260uS,Timer260uS
                Movb #tTimer2mS,Timer2mS
                Movb #$FF,DDRK
                Clr Punt_LCD                   ; Inicializar banderas y puntero
                Bclr Banderas_2,RS
                Bclr Banderas_2,Second_Line
                Bclr Banderas_2,FinSendLCD
                Bset Banderas_2,LCD_Ok
                Ldx #IniDsp
obtiene_Dato    Ldaa 1,X+                 ; Enviar comandos incializacion
                Cmpa #$FF
                Beq ultimo_Char
                Staa CharLCD
                Stx Punt_LCD
espera          Jsr Tarea_SendLCD  ; Enviar al caracter a la pantalla LCD
                Brclr Banderas_2,FinSendLCD,espera
                Bclr Banderas_2,FinSendLCD
                Ldx Punt_LCD
                Bra obtiene_Dato
ultimo_Char     Movb #$01,CharLCD               ; Para el ultimo caracter
espera_1        Jsr Tarea_SendLCD
                Brclr Banderas_2,FinSendLCD,espera_1
                Movb #tTimer2mS,Timer2mS
espera_2        Tst Timer2mS
                Bne espera_2
;===============================================================================
;                    INICIALIZACIÓN MÁQUINAS DE ESTADO
;===============================================================================
        Movw #TConfig_Est1,Est_Pres_TConfig
        Movw #TComp_Est1,Est_Pres_TSelec
        Movw #Tarea_BrilloEst1,Est_Pres_TBrillo
        Movw #TareaTCL_Est1,Est_Pres_TCL
        Movw #Led_Testigo_Est1,Est_Pres_LDTst
        Movw #LeerPB1_Est1,EstPres_LeerPB1
        Movw #LeerPB2_Est1,EstPres_LeerPB2
        Movw #Leer_DS_Est1,Est_Pres_LeerDS
        Movw #PantallaMUX_Est1,EstPres_PantallaMUX
        Movw #Tarea_LCD_Est1,EstPres_TareaLCD
;-------------------------------------------------------------------------------
        Movb #1,Cont_Dig      ; Necesario incializar estas estructuras de datos
        Movb #85,LongOk
;-------------------------------------------------------------------------------
        Clr Banderas_1
        Clr Banderas_2
;---------------------- DESPACHADOR DE TAREAS ----------------------------------

Despachador_Tareas
                        Brset Banderas_2,LCD_OK,otras_Tareas
                        Jsr Tarea_LCD
otras_Tareas            Jsr Tarea_Modo_Stop
                        Jsr Tarea_Configurar
                        Jsr Tarea_Seleccionar
                        Jsr Tarea_Led_Testigo
                        Jsr Tarea_PantallaMUX
                        Jsr Tarea_Teclado
                        Jsr Tarea_Leer_PB1
                        Jsr Tarea_Leer_PB2
                        Jsr Tarea_Brillo
                        Jsr Tarea_Leer_DS

                        Bra Despachador_Tareas
;*******************************************************************************
;                           TAREA MODO STOP
;*******************************************************************************
Tarea_Modo_Stop
                        Ldaa Valor_DS
                        Cmpa #$00
                        Bne FinTarea_Modo_Stop
;-------------------- Reinicio de estados TConfig y TSelec ---------------------
                        Movw #TConfig_Est1,Est_Pres_TConfig  ; permite volver al
                        Movw #TComp_Est1,Est_Pres_TSelec  ; modo sin problemas
;-------------------------------------------------------------------------------
                        Brclr Banderas_2,LCD_OK,FinTarea_Modo_Stop
                        Movb #LDStop,LEDS
                        Movw #Msg_Bienvenida,Msg_L1
                        Movw #Msg_Stop,Msg_L2
                        Bclr Banderas_2,LCD_Ok
                        Movb #$BB,BCD1
                        Movb #$BB,BCD2
                        Jsr BCD_7Seg
FinTarea_Modo_Stop      Rts
;*******************************************************************************
;                               TAREA CONFIGURAR
;*******************************************************************************
Tarea_Configurar
                        Ldaa Valor_DS
                        Cmpa #$40
                        Bne FinTarea_Configurar
                        Movw #TComp_Est1,Est_Pres_TSelec ; Reiniciar otra tarea
                        Ldx Est_Pres_TConfig
                        Jsr 0,X

FinTarea_Configurar     Rts
;=========================== CONFIGURAR ESTADO 1 ===============================
TConfig_Est1            Brclr Banderas_2,LCD_OK,FinTConfig_Est1
                        Movb #LDConfig,LEDS
                        Movw #Msg_Config1,Msg_L1
                        Movw #Msg_Config2,Msg_L2
                        Bclr Banderas_2,LCD_Ok
                        Ldaa LongOK
                        Jsr Bin_BCD_MuxP
                        Movb BCD,BCD1                 ; Enviar a displays 7seg
                        Movb #$BB,BCD2
                        Jsr BCD_7Seg
                        Jsr Borrar_Num_Array
                        Movw #TConfig_Est2,Est_Pres_TConfig
FinTConfig_Est1         Rts
;=========================== CONFIGURAR ESTADO 2 ===============================
TConfig_Est2            Brclr Banderas_1,Array_OK,FinTConfig_Est2
                        Jsr BCD_BIN
                        Ldaa ValorLong
                        Cmpa #Lmin
                        Blo FinTConfig_Est2
                        Cmpa #Lmax
                        Bhi FinTConfig_Est2
                        Jsr Bin_BCD_MuxP
                        Movb BCD,BCD1           ; Enviar a displays 7 seg
                        Movb #$BB,BCD2
                        Jsr BCD_7Seg
                        Movb ValorLong,LongOK
                        Jsr Borrar_Num_Array
FinTConfig_Est2         Bclr Banderas_1,Array_Ok  ; Limpiar bandera Array_Ok
                        Rts
;*******************************************************************************
;                      TAREA MODO SELECCIONAR
;*******************************************************************************
Tarea_Seleccionar
                        Ldaa Valor_DS
                        Cmpa #$C0
                        Bne FinTarea_Seleccionar
                        Movw #TConfig_Est1,Est_Pres_TConfig ; Reiniciar otra tarea
                        Ldx Est_Pres_TSelec
                        Jsr 0,X

FinTarea_Seleccionar    Rts
;=========================== SELECCIONAR ESTADO 1 ==============================
TComp_Est1              Brclr Banderas_2,LCD_OK,FinTComp_Est1 ; Evitar errores pantalla LCD
                        Movb #LDSelect,LEDS
                        Movw #Msg_Seleccionar,Msg_L1
                        Movw #Msg_EsperandoS1,Msg_L2
                        Bclr Banderas_2,LCD_Ok          ; Ir a poner los mensajes
                        Movb #$BB,BCD1     ; Actualizar displays 7 seg
                        Movb #$BB,BCD2
                        Jsr BCD_7Seg
                        Movw #TComp_Est2,Est_Pres_TSelec
FinTComp_Est1           Rts
;=========================== SELECCIONAR ESTADO 2 ==============================
TComp_Est2		Brclr Banderas_1,ShortP1,FinTComp_Est2
                        Movw #Msg_Seleccionar,Msg_L1
                        Movw #Msg_EsperandoS2,Msg_L2
                        Bclr Banderas_2,LCD_Ok     ; Enviar mensajes
                        Bclr Banderas_1,ShortP1
                        Movb #tTimerCal,TimerCal
                        Movw #TComp_Est3,Est_Pres_TSelec
FinTComp_Est2           Rts
;=========================== SELECCIONAR ESTADO 3 ==============================
TComp_Est3              Brclr Banderas_1,ShortP2,FinTComp_Est3
                        Ldaa #100
                        Suba TimerCal
                        Staa DeltaT
                        Movw #Msg_Seleccionar,Msg_L1
                        Movw #Msg_Espera_FinBarra,Msg_L2
                        Bclr Banderas_2,LCD_Ok          ; Enviar mensajes
                        Bclr Banderas_1,ShortP2
                        Movw #TComp_Est4,Est_Pres_TSelec
FinTComp_Est3           Rts
;=========================== SELECCIONAR ESTADO 4 ==============================
TComp_Est4              Brclr Banderas_1,ShortP2,FinTComp_Est4  ; Esperar ShortP2
                        Jsr Calcula
                        Bclr Banderas_1,ShortP2
                        Ldaa Velocidad       ; Compara velocidad para ver si
                        Cmpa #VelocMin       ; cumple los parámetros
                        Blo msg_error_vel
                        Cmpa #VelocMax
                        Bhi msg_error_vel
                        Ldaa Longitud           ; Compara longitud para ver si
                        Cmpa LongOK              ; cumple los parámetros
                        Blo msg_error_lon
                        Cmpa #Lmax
                        Bhi msg_error_lon
                        Movw #Msg_Calculando,Msg_L2     ; En este caso si cumplio
                        Bclr Banderas_2,LCD_OK
                        Movw #TComp_Est5,Est_Pres_TSelec
                        Bra FinTComp_Est4
msg_error_vel           Movw #Msg_Alerta_Velocidad,Msg_L1
                        Movw #Msg_Alerta_FueraRango,Msg_L2
                        Bclr Banderas_2,LCD_OK 	   ; Enviar mensajes a pantalla LCD
                        Bra  limpiar_var
msg_error_lon           Movw #Msg_Alerta_Longitud,Msg_L1
                        Movw #Msg_Alerta_FueraRango,Msg_L2
                        Bclr Banderas_2,LCD_OK       ; Enviar mensajes a pantalla LCD
limpiar_var             Clr Velocidad            ; Limpiar valores calculados
                        Clr Longitud
                        Clr TimerPant
                        Clr TimerRociador
                        Clr TimerFinPant
                        Movb #$AA,BCD1          ; Mover guiones a displays 7 seg
                        Movb #$AA,BCD2
                        Jsr BCD_7Seg
                        Movb #tTimerError,TimerError
                        Movw #TComp_Est6,Est_Pres_TSelec
FinTComp_Est4           Rts
;=========================== SELECCIONAR ESTADO 5 ==============================
TComp_Est5              Tst TimerPant           ; Espera a que acabe Timer Pant
                        Bne FinTComp_Est5
                        Movw #Msg_Seleccionar,Msg_L1
                        Movw #Msg_Resultados,Msg_L2
                        Bclr Banderas_2,LCD_OK  ; Enviar mensaje de resultados
                        Ldaa Velocidad       ; Convertir velocidad a BCD
                        Jsr BIN_BCD_MUXP
                        Movb BCD,BCD2
                        Ldaa Longitud       ; Convertir longiutd a BCD
                        Jsr BIN_BCD_MUXP
                        Movb BCD,BCD1
                        Jsr BCD_7Seg            ; Colocar valores en displays 7 seg
                        Movw #TComp_Est7,Est_Pres_TSelec
FinTComp_Est5           Rts
;=========================== SELECCIONAR ESTADO 6 ==============================
TComp_Est6              Tst TimerError          ; Tiempo de espera para msg error
                        Bne FinTComp_Est6
                        Movw #TComp_Est1,Est_Pres_TSelec
FinTComp_Est6           Rts
;=========================== SELECCIONAR ESTADO 7 ==============================
TComp_Est7              Tst TimerRociador     ; Esperar a que pase TimerRociador
                        Bne FinTComp_Est7
                        Movb #tTimerShot,TimerShot
                        Bset PORTE,$04      ; Encender el rele
                        Movw #TComp_Est8,Est_Pres_TSelec
FinTComp_Est7           Rts
;=========================== SELECCIONAR ESTADO 8 ==============================
TComp_Est8              Tst TimerShot         ; Esperar a que pase TimerShot
                        Bne FinTComp_Est8
                        Bclr PORTE,$04          ; Apagar el rele
                        Tst TimerFinPant
                        Bne FinTComp_Est8
                        Movw #TComp_Est1,Est_Pres_TSelec
FinTComp_Est8           Rts
;*******************************************************************************
;                               TAREA BRILLO
;*******************************************************************************
Tarea_Brillo
                        Ldx Est_Pres_TBrillo
                        Jsr 0,X

FinTarea_Brillo            Rts
;=========================== BRILLO ESTADO 1 ===================================
Tarea_BrilloEst1        Movb #tTimerBrillo,TimerBrillo
                        Movw #Tarea_BrilloEst2,Est_Pres_TBrillo
                        Rts
;=========================== BRILLO ESTADO 2 ===================================
Tarea_BrilloEst2        Tst TimerBrillo
                        Bne FinTarea_BrilloEst2
                        Movb #$87,ATD0CTL5      ; Realizar lectura
                        Movw #Tarea_BrilloEst3,Est_Pres_TBrillo
FinTarea_BrilloEst2     Rts
;=========================== BRILLO ESTADO 3 ===================================
Tarea_BrilloEst3        Brclr ATD0STAT0,MaskSCF,FinTarea_BrilloEst3
                        Ldd ADR00H        ;Obtener el promedio, sumando y dividiendo
                        Addd ADR01H       ; entre 4
                        Addd ADR02H
                        Addd ADR03H
                        Lsrd
                        Lsrd
                        Ldx #3            ; Progresion lineal, dividir entre 3
                        Idiv
                        Tfr X,D
                        Stab Brillo        ; Obtener el valor del brillo
                        Movw #Tarea_BrilloEst1,Est_Pres_TBrillo
FinTarea_BrilloEst3     Rts
;*******************************************************************************
;                               TAREA TECLADO
;*******************************************************************************
Tarea_Teclado
                 Ldx Est_Pres_TCL
                 Jsr 0,X

Fin_TareaTeclado Rts
;=========================== TAREA TECLADO ESTADO 1 ============================
TareaTCL_Est1
                Jsr Leer_Teclado  ; Obtener la tecla presionada
                Ldaa Tecla
                Cmpa #$FF
                Beq Fin_TCL_Est1
                Movb #tSuprRebTCL,Timer_RebTCL  ; Si es una tecla valida, carga
                Movw #TareaTCL_Est2,Est_Pres_TCL ; timers y brinca a Est2
Fin_TCL_Est1    Rts
;=========================== TAREA TECLADO ESTADO 2 ============================
TareaTCL_Est2
                Tst Timer_RebTCL        ; Tiempo de espera timer de rebotes
                Bne Fin_TCL_Est2
                Movb Tecla,Tecla_IN  ; Leer de nuevo para verificar si la tecla
                Jsr Leer_Teclado   ; sigue presionada
                Ldaa Tecla
                Cmpa Tecla_IN
                Bne volver_Est1
                Movw #TareaTCL_Est3,Est_Pres_TCL  ; Si la tecla es igual, brinca
                Bra Fin_TCL_Est2                  ; a Est3
volver_Est1     Movw #TareaTCL_Est1,Est_Pres_TCL ; Si es diferente vuelve a Est1
Fin_TCL_Est2    Rts
;=========================== TAREA TECLADO ESTADO 3 ============================
TareaTCL_Est3
                Jsr Leer_Teclado
                Ldaa Tecla
                Cmpa #$FF
                Bne Fin_TCL_Est3        ; Espera a que no se deje de presionar
                Movw #TareaTCL_Est4,Est_Pres_TCL ; la tecla, va a Est4
Fin_TCL_Est3    Rts
;=========================== TAREA TECLADO ESTADO 4 ============================
TareaTCL_Est4
                Ldx #Num_Array          ; Cargar indice y offset
                Ldaa Cont_TCL
                Cmpa MAX_TCL
                Bne no_Max_TCL
                Ldab Tecla_IN
                Cmpb #$0B ; Si el arreglo esta completo, solo se puede presionar
                Bne comp_Enter ; borrar y enter
                Deca
                Movb #$FF,A,X         ; Borrar una tecla del arreglo Num_Array
                Staa Cont_TCL
                Bra Fin_TCL_Est4
comp_Enter      Cmpb #$0E
                Bne Fin_TCL_Est4 ; Si la tecla no es borrar ni enter, retorna
                Bra enter_Valido
no_Max_TCL      Tsta
                Bne no_Es_Primero
                Ldab Tecla_IN  ; Tecla_IN es primero, no se puede presionar
                Cmpb #$0B      ; borrar ni enter
                Beq Fin_TCL_Est4
                Cmpb #$0E
                Beq Fin_TCL_Est4
                Movb Tecla_IN,A,X  ; Si es otra tecla, se coloca en el arreglo
                Inca
                Staa Cont_TCL      ; Se actualiza el offset
                Bra Fin_TCL_Est4
no_Es_Primero   Ldab Tecla_IN   ; Si no es el primer elemento, se puede utilizar
                Cmpb #$0B       ; cualquier tecla
                Bne comp_Enter_2
                Deca
                Movb #$FF,A,X  ; Borrar ultimo elemento y decrementar offset
                Staa Cont_TCL
                Bra Fin_TCL_Est4
comp_Enter_2    Cmpb #$0E
                Beq enter_Valido
                Movb Tecla_IN,A,X       ; Colocar tecla en el arreglo
                Inca
                Staa Cont_TCL           ; Actualizar offset
                Bra Fin_TCL_Est4
enter_Valido    Clr Cont_TCL
                Bset Banderas_1,Array_OK  ; Al dar enter, Array_OK = 1
Fin_TCL_Est4    Movw #TareaTCL_Est1,Est_Pres_TCL
                Movb #$FF,Tecla_IN      ; Limpiar Tecla_IN
                Rts
;*******************************************************************************
;                               TAREA LED TESTIGO
;*******************************************************************************
Tarea_Led_Testigo
                        Ldx Est_Pres_LDTst
                        Jsr 0,X

FinLedTest              Rts
;========================== LED_TESTIGO_EST1 ===================================
Led_Testigo_Est1
                        Tst Timer_LED_Testigo
                        Bne Fin_Led_Testigo_Est1  ; Esperar a que el timer sea 0
                        Movb #tTimerLDTst,Timer_LED_Testigo    ; Recarga timer
                        Bclr PTP,LD_Blue
                        Bset PTP,LD_Red
                        Movw #Led_Testigo_Est2,Est_Pres_LDTst
Fin_Led_Testigo_Est1    Rts
;========================== LED_TESTIGO_EST2 ===================================
Led_Testigo_Est2
                        Tst Timer_LED_Testigo
                        Bne Fin_Led_Testigo_Est2  ; Esperar a que el timer sea 0
                        Movb #tTimerLDTst,Timer_LED_Testigo    ; Recarga timer
                        Bclr PTP,LD_Red
                        Bset PTP,LD_Green
                        Movw #Led_Testigo_Est3,Est_Pres_LDTst
Fin_Led_Testigo_Est2    Rts
;========================== LED_TESTIGO_EST3 ===================================
Led_Testigo_Est3
                        Tst Timer_LED_Testigo
                        Bne Fin_Led_Testigo_Est3  ; Esperar a que el timer sea 0
                        Movb #tTimerLDTst,Timer_LED_Testigo    ; Recarga timer
                        Bclr PTP,LD_Green
                        Bset PTP,LD_Blue
                        Movw #Led_Testigo_Est1,Est_Pres_LDTst
Fin_Led_Testigo_Est3    Rts
;*******************************************************************************
;                               TAREA LEER PB1
;*******************************************************************************
Tarea_Leer_PB1
                Ldx EstPres_LeerPB1
                Jsr 0,X

FinTareaPB1     Rts
;=========================== LEER PB ESTADO 1 ==================================
LeerPB1_Est1    Brclr PTIH,MaskPB1,Lazo_1
Retornos_1      Rts
Lazo_1          Movb #tSupRebPB,Timer_RebPB1  ; Si detecta una tecla carga timers
                Movb #tShortP,Timer_SHP1      ; y pasa al estado 2
                Movb #tLongP,Timer_LP1
                Movw #LeerPB1_Est2,EstPres_LeerPB1
                Bra Retornos_1
;=========================== LEER PB ESTADO 2 ==================================
LeerPB1_Est2    Tst Timer_RebPB1
                Bne Retornos_2         ; Tiempo de espera hasta que timer sea 0
                Brclr PTIH,MaskPB1,Presionado
                Movw #LeerPB1_Est1,EstPres_LeerPB1
                Bra Retornos_2
Presionado      Movw #LeerPB1_Est3,EstPres_LeerPB1  ; Tecla presionada descarta
Retornos_2      Rts                                ; rebotes mecanicos (a est3)
;=========================== LEER PB ESTADO 3 ==================================
LeerPB1_Est3    Tst Timer_SHP1
                Bne Retornos_3    ; Tiempo de espera para short press
                Brclr PTIH,MaskPB1,Presionado_2
                Bset Banderas_1,ShortP1    ; Al dejar de presionar el boton, vuelve
                Movw #LeerPB1_Est1,EstPres_LeerPB1 ; al estado 1, se asume shp
                Bra Retornos_3
Presionado_2    Movw #LeerPB1_Est4,EstPres_LeerPB1 ;Si sigue presionado va a est4
Retornos_3      Rts
;=========================== LEER PB ESTADO 4 ==================================
LeerPB1_Est4    Tst Timer_LP1
                Bne branch_1
                Brclr PTIH,MaskPB1,Retornos_4
                Bset Banderas_1,LongP1 ; Si el timer llego a 0 y la tecla no esta
                Bra Definir_prox    ; presionada, se interpreta longPress
branch_1        Brclr PTIH,MaskPB1,Retornos_4
                Bset Banderas_1,ShortP1 ; Si el timer no llego a 0 es shortPress
Definir_prox    Movw #LeerPB1_Est1,EstPres_LeerPB1
Retornos_4      Rts
;*******************************************************************************
;                               TAREA LEER PB2
;*******************************************************************************
Tarea_Leer_PB2
                Ldx EstPres_LeerPB2
                Jsr 0,X

FinTareaPB2     Rts
;=========================== LEER PB ESTADO 1 ==================================
LeerPB2_Est1    Brclr PTIH,MaskPB2,Lazo_1b
Retornos_1b     Rts
Lazo_1b         Movb #tSupRebPB,Timer_RebPB2  ; Si detecta una tecla carga timers
                Movb #tShortP,Timer_SHP2      ; y pasa al estado 2
                Movb #tLongP,Timer_LP2
                Movw #LeerPB2_Est2,EstPres_LeerPB2
                Bra Retornos_1b
;=========================== LEER PB ESTADO 2 ==================================
LeerPB2_Est2    Tst Timer_RebPB2
                Bne Retornos_2b        ; Tiempo de espera hasta que timer sea 0
                Brclr PTIH,MaskPB2,Presionado_b
                Movw #LeerPB2_Est1,EstPres_LeerPB2
                Bra Retornos_2b
Presionado_b    Movw #LeerPB2_Est3,EstPres_LeerPB2  ; Tecla presionada descarta
Retornos_2b     Rts                                ; rebotes mecanicos (a est3)
;=========================== LEER PB ESTADO 3 ==================================
LeerPB2_Est3    Tst Timer_SHP2
                Bne Retornos_3b    ; Tiempo de espera para short press
                Brclr PTIH,MaskPB2,Presionado_2b
                Bset Banderas_1,ShortP2    ; Al dejar de presionar el boton, vuelve
                Movw #LeerPB2_Est1,EstPres_LeerPB2 ; al estado 1, se asume shp
                Bra Retornos_3b
Presionado_2b   Movw #LeerPB2_Est4,EstPres_LeerPB2 ;Si sigue presionado va a est4
Retornos_3b     Rts
;=========================== LEER PB ESTADO 4 ==================================
LeerPB2_Est4    Tst Timer_LP2
                Bne branch_1b
                Brclr PTIH,MaskPB2,Retornos_4b
                Bset Banderas_1,LongP2 ; Si el timer llego a 0 y la tecla no esta
                Bra Definir_prox_b    ; presionada, se interpreta longPress
branch_1b       Brclr PTIH,MaskPB2,Retornos_4b
                Bset Banderas_1,ShortP2 ; Si el timer no llego a 0 es shortPress
Definir_prox_b  Movw #LeerPB2_Est1,EstPres_LeerPB2
Retornos_4b     Rts
;******************************************************************************
;                              TAREA LEER DS
;******************************************************************************
Tarea_Leer_DS
                        Ldx Est_Pres_LeerDS
                        Jsr 0,X
Fin_Tarea_Leer_DS       Rts
;===========================  LEER DS EST1  ====================================
Leer_DS_Est1            Movb PTH,Temp_DS
                        Movb #tTimerRebDS,Timer_RebDS
                        Movw #Leer_DS_Est2,Est_Pres_LeerDS
Fin_Leer_DS_Est1        Rts
;===========================  LEER DS EST2  ====================================
Leer_DS_Est2            Tst Timer_RebDS
                        Bne Fin_Leer_DS_Est2
                        Ldaa Temp_DS
                        Cmpa PTH                ; Comparar Temp_DS con PTH
                        Bne cambiar_est1
                        Ldaa PTH                 ; Si son igual, hace mascara
                        Anda #$C0           ; para solo tomar en cuenta PH7 y PH6
                        Staa Valor_DS
cambiar_est1            Movw #Leer_DS_Est1,Est_Pres_LeerDS
Fin_Leer_DS_Est2        Rts
;******************************************************************************
;                               TAREA PANTALLA MUX
;******************************************************************************
Tarea_PantallaMUX
                        Ldx EstPres_PantallaMUX
                        Jsr 0,X
Fin_PantallaMUX         Rts
;======================  TAREA PANTALLA MUX EST1  ==============================
PantallaMUX_Est1
                        Tst TimerDigito
                        Bne Fin_PantallaMUX_Est1 ; Esperar a que pase tiempo dig
                        Movb #tTimerDigito,TimerDigito
                        Bset PTJ,$02            ; Habilitar los LEDS
                        Ldaa Cont_Dig
                        CMPA #1
                        Bne comparar_2
                        Bset PTP,$0E                ; Colocar Dsp1
                        Bclr PTP,$01
                        Movb Dsp1,PORTB
                        Bra incre
comparar_2              CMPA #2
                        Bne comparar_3
                        Bset PTP,$0D                ; Colocar Dsp2
                        Bclr PTP,$02
                        Movb Dsp2,PORTB
                        Bra incre
comparar_3              CMPA #3
                        Bne comparar_4
                        Bset PTP,$0B                ; Colocar Dsp3
                        Bclr PTP,$04
                        Movb Dsp3,PORTB
                        Bra incre
comparar_4              CMPA #4
                        Bne reinicio
                        Bset PTP,$07	; Colocar Dsp4
                        Bclr PTP,$08
                        Movb Dsp4,PORTB
                        Bra incre
Fin_PantallaMUX_Est1    Rts
reinicio                Bset PTP,$0F
                        BClr PTJ,$02            ; Habilitar los LEDS
                        Movb LEDS,PORTB
                        Movb #1,Cont_Dig
                        Bra cambia_Est
incre                   Inc Cont_Dig
cambia_Est              Movw #MaxCountTicks,Counter_Ticks
                        Movw #PantallaMUX_Est2,EstPres_PantallaMUX
                        Bra Fin_PantallaMUX_Est1
;======================  TAREA PANTALLA MUX EST2  ==============================
PantallaMUX_Est2        Ldd #MaxCountTicks
                        Subd Counter_Ticks
                        Cmpb Brillo      ; Reinicia LEDS y Display al acabar
                        Blo Fin_PantallaMUX_Est2    ; el tiempo de brillo
                        Bset PTJ,$02           ; Deshabilitar los LEDS
                        Movw #PantallaMUX_Est1,EstPres_PantallaMUX
Fin_PantallaMUX_Est2    Rts
;******************************************************************************
;                               TAREA LCD
;******************************************************************************
Tarea_LCD               Ldx EstPres_TareaLCD
                        Jsr 0,X

Fin_Tarea_LCD           Rts
;=============================  TAREA LCD EST1  ================================
Tarea_LCD_Est1
                        Bclr Banderas_2,FinSendLCD      ; Borrar banderas
                        Bclr Banderas_2,RS
                        Brset Banderas_2,Second_Line,line2
                        Movb #ADD_L1,CharLCD             ; Transmitir linea 1
                        Movw Msg_L1,Punt_LCD
                        Bra Fin_Tarea_LCD_Est1
line2                   Movb #ADD_L2,CharLCD             ; Transmitir linea 2
                        Movw Msg_L2,Punt_LCD
Fin_Tarea_LCD_Est1      Jsr Tarea_SendLCD               ; Enviar a pantalla
                        Movw #Tarea_LCD_Est2,EstPres_TareaLCD  ; Brincar a est2
                        Rts
;=============================  TAREA LCD EST2  ================================
Tarea_LCD_Est2
                       Brclr Banderas_2,FinSendLCD,enviarLCD
                       Bclr Banderas_2,FinSendLCD  ; Si ya se envio, borra band
                       Bset Banderas_2,RS
                       Ldx Punt_LCD           ; Acceder dir. indexado post-inc
                       Ldaa 1,X+
                       Staa CharLCD
                       Stx Punt_LCD
                       Cmpa #$FF            ; Verificar si es el end of block
                       Bne enviarLCD
                       Brclr Banderas_2,Second_Line,poner_Bandera
                       Bclr Banderas_2,Second_Line
                       Bset Banderas_2,LCD_OK
                       Bra cambiar_Estado
poner_Bandera          Bset Banderas_2,Second_Line
cambiar_Estado         Movw #Tarea_LCD_Est1,EstPres_TareaLCD
                       Bra Fin_Tarea_LCD_Est2
enviarLCD              Jsr Tarea_SendLCD
Fin_Tarea_LCD_Est2     Rts
;******************************************************************************
;                               TAREA SendLCD
;******************************************************************************
Tarea_SendLCD
                        Ldx EstPres_SendLCD
                        Jsr 0,X
Fin_Tarea_SendLCD       Rts
;=========================  TAREA SendLCD EST1  ================================
SendLCD_Est1
                        Ldaa CharLCD
                        Anda #$F0               ; Obtener parte alta CharLCD
                        Lsra
                        Lsra
                        Staa PORTK              ; Poner en PORTK 5-2
                        Brclr Banderas_2,RS,poner_Cero
                        Bset PORTK,RS         ; Modificar registros de control
                        Bra Fin_SendLCD_Est1
poner_Cero              Bclr PORTK,RS
Fin_SendLCD_Est1        Bset PORTK,$02
                        Movw #tTimer260uS,Timer260uS
                        Movw #SendLCD_Est2,EstPres_SendLCD  ; Saltar a Est2
                        Rts

;=========================  TAREA SendLCD EST2  ================================
SendLCD_Est2
                        Ldd Timer260uS
                        Bne Fin_SendLCD_Est2    ; Esperar a que termine timer
                        Bclr PORTK,$02
                        Ldaa CharLCD    ; Ahora se carga parte baja del Char
                        Anda #$0F
                        Lsla
                        Lsla
                        Staa PORTK      ; Cargar en PORTK 5-2
                        Brclr Banderas_2,RS,poner_Cero_1
                        Bset PORTK,RS         ; Modificar registros de control
                        Bra cambiar_Est
poner_Cero_1            Bclr PORTK,RS
cambiar_Est             Bset PORTK,$02
                        Movw #tTimer260uS,Timer260uS
                        Movw #SendLCD_Est3,EstPres_SendLCD  ; Saltar a Est2
Fin_SendLCD_Est2        Rts
;=========================  TAREA SendLCD EST3  ================================
SendLCD_Est3
                        Ldd Timer260uS
                        Bne Fin_SendLCD_Est3    ; Esperar a que acaba el timer
                        Bclr PORTK,$02
                        Movw #tTimer40uS,Timer40uS
                        Movw #SendLCD_Est4,EstPres_SendLCD ; Brinca a estado 4
Fin_SendLCD_Est3        Rts
;=========================  TAREA SendLCD EST4  ================================
SendLCD_Est4            Ldd Timer40uS           ; Esperar
                        Bne Fin_SendLCD_Est4
                        Bset Banderas_2,FinSendLCD ; indicar que termino envio
                        Movw #SendLCD_Est1,EstPres_SendLCD  ; Volver al inicio
Fin_SendLCD_Est4        Rts
;*******************************************************************************
;                       SUBRUTINA BCD_BIN
;*******************************************************************************
BCD_BIN
                        Ldx #Num_Array
                        Ldaa 1,X+               ; Traer decenas
                        Lsla                    ; Multiplicar A por 2
                        Tab
                        Lslb                    ; Multiplicar B por 8
                        Lslb
                        Aba
                        Ldab 0,X                ; Traer unidades
                        Aba                     ; Sumar centenas y unidades
                        Staa ValorLong          ; Listo para comparar
                        Rts
;*******************************************************************************
;                       SUBRUTINA CALCULA
;*******************************************************************************
Calcula
                        Clra                    ; Inicia calculando velocidad
                        Ldab DeltaT
                        Tfr D,X
                        Ldaa #DeltaX_S
                        Ldab #10
                        
                        Mul
                        Idiv
                        Tfr X,D
                        Stab Velocidad
                        
                        Ldaa #100               ; Se recalcula DeltaT
                        Suba TimerCal
                        Suba DeltaT
                        Staa DeltaT
                        
                        Mul                     ; Calculo Longitud
                        Ldx #10
                        Idiv
                        Tfr X,D
                        Stab Longitud
                        
                        Clra                        ; Calculo TimerPant
                        Ldab Velocidad
                        Tfr D,X
                        Ldaa #DeltaX_R
                        Suba Longitud
                        Ldab #10
                        Mul
                        Idiv
                        Tfr X,D
                        Stab TimerPant
                        
                        Clra                        ; Calculo TimerFinPant
                        Ldab Velocidad
                        Tfr D,X
                        Ldaa #DeltaX_R
                        Ldab #10
                        Mul
                        Idiv
                        Tfr X,D
                        Stab TimerFinPant
                        
                        Clra                    ; Calculo TimerRociador
                        Ldab Velocidad
                        Tfr D,X
                        Ldaa #DeltaX_R
                        Ldab Longitud
                        Lsrb
                        Sba
                        Ldab #10
                        
                        Mul
                        Idiv
                        Tfr X,D
                        Stab TimerRociador
                        
                        Movb #tTimerShot,TimerShot
                        Rts
;******************************************************************************
;                       SUBRUTINA BIN_BCD_MUXP
;******************************************************************************
Bin_BCD_MuxP
                Movb #7,Cont_BCD      ; Se utilizara contador de desplazamiento
                Clr BCD
desp            Lsla                  ; Ejecutar desplazamiento
                Rol BCD
                Psha        ; Guardar temporalmente valor binario desplazado
                Ldaa BCD
                Anda #$0F   ; Obtener la parte baja del numero hasta el momento
                Cmpa #5     ; Si es mayor o igual a 5, suma 3 al nibble
                Blo no_Suma
                Adda #3
no_Suma         Ldab BCD
                Andb #$F0
                Cmpb #$50     ; Si es mayor o igual a 5, suma 3 al nibble
                Blo no_Suma_1
                Addb #$30
no_Suma_1       Aba             ; Sumar parte alta y parte baja
                Staa BCD    ; Modificar valor en BCD
                Pula    ; Recuperar valor binario desplazado
                Dec Cont_BCD
                Bne desp   ; Se devuelve para desplazar bits faltantes
                Lsla       ; El ultimo desplazamiento no se revisa
                Rol BCD
Fin_Bin_BCD     Rts
;******************************************************************************
;                       SUBRUTINA BCD-7Seg
;******************************************************************************
BCD_7Seg
                Ldx #Segment            ; Obtener direccion de la tabla
                Ldaa BCD1
                Anda #$F0              ; Obtener parte alta de BCD1
                Ldab #4                ; Desplazar 4 veces
rotar           Lsra
                Dbne B,rotar
                Movb A,X,Dsp3           ; Valor para colocar en el display3
                Ldaa BCD1
                Anda #$0F             ; Obtener parte baja de BCD1
                Movb A,X,Dsp4
                Ldaa BCD2
                Anda #$F0               ; Obtener parte alta de BCD2
                Ldab #4
rotar_1         Lsra
                Dbne B,rotar_1
                Movb A,X,Dsp1
                Ldaa BCD2
                Anda #$0F               ; Obtener parte baja de BCD2
                Movb A,X,Dsp2
Fin_BCD_7Seg    Rts
;*******************************************************************************
;                       SUBRUTINA BORRAR_NUM_ARRAY
;*******************************************************************************
Borrar_Num_Array
                        Ldx #Num_Array          ; Cargar indice
                        Clra
Set_FF                  Ldab 0,X
                        Cmpb #$FF ;Si la pos actual esta borrada, las siguientes
                        Beq Fin_Borrar_Num_Array ; tambien estaran borradas
                        Movb #$FF,1,X+  ; Borrar elemento del arreglo
                        Inca
                        Cmpa MAX_TCL    ; Si se alcanzo MAX_TCL, ya se borro
                        Bne Set_FF      ; todo Num_Array
Fin_Borrar_Num_Array    Bset Banderas_1,Array_OK
                        Rts

;*******************************************************************************
;                      SUBRUTINA LEER_TECLADO
;*******************************************************************************
Leer_Teclado
                Ldx #Teclas             ; Inicializar indices
                Clra
                Movb #$EF,PATRON
detectar_Tecla  Movb PATRON,PORTA       ; Revision de filas
                Brclr PORTA,$02,poner_Tecla     ; Revisar columnas
                Inca                            ; Ajustar offset
                Brclr PORTA,$04,poner_Tecla
                Inca
                Brclr PORTA,$08,poner_Tecla
                Inca
                Lsl PATRON      ; Revisar siguiente fila del teclado
                Ldab PATRON
                Cmpb #$F0       ; Verificar si ya se revisaron todas las filas
                Beq sin_Tecla
                Bra detectar_Tecla
poner_Tecla     Movb A,X,Tecla
                Bra Fin_LeerTeclado
sin_Tecla       Movb #$FF,Tecla         ; Si no se presiona tecla coloca $FF
Fin_LeerTeclado Rts
;******************************************************************************
;        SUBRUTINA DE ATENCION DE INTERRUPCIONES (MAQUINA DE TIEMPOS)
;******************************************************************************

Maquina_Tiempos
                        Ldd TCNT        ; Frecuencia en el canal 4
                        Addd #Carga_TC4
                        Std TC4
                        Ldx #Tabla_Timers_BaseT ; Decrementar bases de tiempo
                        Jsr Decre_Timers_BaseT
unmS                    Ldd Timer1mS
                        Bne diezmS
                        Movw #tTimer1mS,Timer1mS   ; Decrementar timers de 1mS
                        Ldx #Tabla_Timers_Base1mS
                        Jsr Decre_Timers
diezmS                  Ldd Timer10mS
                        Bne cienmS
                        Movw #tTimer10mS,Timer10mS;Decrementar timers de 10mS...
                        Ldx #Tabla_Timers_Base10mS
                        Jsr Decre_Timers
cienmS                  Ldd Timer100mS
                        Bne unS
                        Movw #tTimer100mS,Timer100mS
                        Ldx #Tabla_Timers_Base100mS
                        Jsr Decre_Timers
unS                     Ldd Timer1S
                        Bne final_subrutina
                        Movw #tTimer1S,Timer1S
                        Ldx #Tabla_Timers_Base1S
                        Jsr Decre_Timers
final_subrutina         RTI
;----------------- SUBRUTINA DECRE_TIMERS_BASET --------------------------------
Decre_Timers_BaseT      Ldy 2,x+
                        Beq Decre_Timers_BaseT
                        Cpy #$FFFF
                        Beq fin_Decre_Timers_BaseT
                        Dey
                        Sty -2,x
                        Bra Decre_Timers_BaseT
fin_Decre_Timers_BaseT  Rts
;-------------------- SUBRUTINA DECRE_TIMERS -----------------------------------
Decre_Timers            Ldaa 0,x
                        Bne sig_comparacion
                        Inx
                        Bra Decre_Timers
sig_comparacion         Cmpa #$FF
                        Beq fin_Decre_Timers
                        Dec 0,x
                        Inx
                        Bra Decre_Timers
fin_Decre_Timers        Rts