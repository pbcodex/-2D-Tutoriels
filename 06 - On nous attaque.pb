;Invader

;
;Objectif de cet exercice
;   Afficher un vaisseau en bas de l'ecran se déplaçant avec les touches gauche et droite du clavier
;   Afficher un ennemi en haut de l'ecran se déplaçant de gauche à droite de maniere autonome
;

EnableExplicit

Enumeration Window
  #MainForm
EndEnumeration

;Vaisseau
Global Ship, ShipX = 350, ShipY = 500, ShipLife = 5  

;Enemy : Position x, y et nombre de vies
Global Enemy, EnemyX = 350, EnemyY = 100, EnemyLife = 5, EnemyDirection = 1

;Structure d'un nouveau tir
Structure NewShoot
  Sprite.i    ;Identifiant du sprite représentant un tir
  x.i         ;Position x du tir
  y.i         ;Position y du tir
EndStructure

;Stockage de tous les tirs du joueurs dans une liste chainée
Global NewList PlayerShoots.NewShoot()

;Stockage de tous les tirs de l'ennemi dans une liste chainée
Global NewList EnemyShoots.NewShoot()

;Autorisation de tir
Global ShootAuthorization = #True

;Model de tir 
Global Shoot, ShootTime

;Information
Global Info

;Evenement et compteur de boucles
Global Event

;Dossier média
Global FolderImages.s = "assets\/images\/"

;Initialisation de l'environnement 2D
InitSprite() : InitKeyboard()

;Creation de la surface de jeu
OpenWindow(#MainForm, 0, 0, 800, 600, "Dessiner dans un sprite", #PB_Window_SystemMenu|#PB_Window_ScreenCentered)
OpenWindowedScreen(WindowID(#MainForm), 0, 0, 800, 600)

;-Chargement et création des sprites
UsePNGImageDecoder()

Ship  = LoadSprite(#PB_Any, FolderImages + "ship.png", #PB_Sprite_AlphaBlending)
Enemy = LoadSprite(#PB_Any, FolderImages + "enemy.png", #PB_Sprite_AlphaBlending)
Shoot = LoadSprite(#PB_Any, FolderImages + "shoot.png")

;Création du sprite permettant d'afficher des informations 
Info = CreateSprite(#PB_Any, 800, 30)

;-Boucle evenementielle
Repeat  ;Evenement du jeu
  Repeat;Evenement window
    Event = WindowEvent()
    
    Select Event    
      Case #PB_Event_CloseWindow
        End
    EndSelect  
  Until Event=0
  
  ; 1 - Effacer l'ecran avec une couleur avant d'afficher les sprites
  ClearScreen(RGB(0, 0, 0)) ;Commenter pour voir ce qu'il se passe
  
  ; 2 - Affichage des sprites
  
  ;Affichage du vaisseau
  If ShipLife > 0
    DisplayTransparentSprite(Ship, ShipX, ShipY)
  EndIf
  
  ;Affichage de l'ennemi
  If EnemyLife > 0
    DisplayTransparentSprite(Enemy, EnemyX, EnemyY)
  EndIf
  
  ;-Affichage des shoots du player
  ForEach PlayerShoots()
    PlayerShoots()\y - 2 ;Chaque shoot remonte de deux  pixels
    
    ;Ce tir sort t'il en haut de l'écran ?
    If PlayerShoots()\y < 0
      FreeSprite(PlayerShoots()\Sprite) ;Destruction du tir
      DeleteElement(PlayerShoots(), #True)  ;Destruction des information du tir
      
    Else
      
      DisplaySprite(PlayerShoots()\Sprite, PlayerShoots()\x, PlayerShoots()\y)
      
      ;Il y a t'il collision entre un shoot et l'ennemi ?
      ;Un tir sort t'il en haut de l'écran ?
      ;   Syntaxe : SpriteCollision(#Sprite1, x1, y1, #Sprite2, x2, y2)
      If EnemyLife > 0 And SpriteCollision(Enemy, EnemyX, EnemyY, PlayerShoots()\Sprite, PlayerShoots()\x, PlayerShoots()\y)    
        FreeSprite(PlayerShoots()\Sprite) ;Destruction du tir
        DeleteElement(PlayerShoots(), #True) ;Destruction des information du tir
        
        ;Diminution du nombre de vie ou destruction de l'ennemi
        If EnemyLife > 0
          EnemyLife - 1
        ElseIf EnemyLife = 0
          FreeSprite(Enemy) ;C'est terminé pour lui
        EndIf
      EndIf
    EndIf 
  Next
  
  ;-Affichage des shoots de l'ennemi
  ForEach EnemyShoots()
    EnemyShoots()\y + 2 ;Chaque shoot de l'ennemi descend de deux  pixels
    
    ;Ce tir sort t'il en bas de l'écran ?
    If EnemyShoots()\y > 600
      FreeSprite(EnemyShoots()\Sprite) ;Destruction du tir
      DeleteElement(EnemyShoots(), #True) ;Destruction des information du tir
      
    Else
      
      DisplaySprite(EnemyShoots()\Sprite, EnemyShoots()\x, EnemyShoots()\y)    
      If ShipLife > 0 And SpriteCollision(Ship, ShipX, ShipY, EnemyShoots()\Sprite, EnemyShoots()\x, EnemyShoots()\y)    
        FreeSprite(EnemyShoots()\Sprite) ;Destruction du tir
        DeleteElement(EnemyShoots(), #True) ;Destruction des information du tir
        
        ;Diminution du nombre de vie ou destruction du vaisseau (Player)
        ShipLife - 1
        If ShipLife = 1
          FreeSprite(Ship) ;C'est terminé pour lui
        EndIf
      EndIf
    EndIf    
  Next
  
  ;Affichage du bandeau d'information
  ;Dessinons dans le sprite
  StartDrawing(SpriteOutput(Info))
  Box(0, 0, 800, 30, RGB(128, 128, 128))
  DrawingMode(#PB_2DDrawing_Transparent)
  DrawText(5, 5, "[Esc] Quitter le jeu  -  [Espace] Tirer  -  Position x du vaisseau " + ShipX + "  -  Nombre de vie " + ShipLife, RGB(220, 220, 220))
  StopDrawing()
  
  DisplaySprite(Info, 0, 570)
  
  ; 3 - Examinons si une touche du clavier est préssée
  ExamineKeyboard()
  
  ;Déplacement du vaisseau avec les touches droite ou gauche
  ;Le vaisseau ne doit pas sortir des limites gauche et droite de la surface du jeu
  ;Le vaisseau doit avoir un nombre de vie > 0
  If ShipLife > 0
    If KeyboardPushed(#PB_Key_Left) And ShipX > 0
      ShipX - 2 ;Le vaisseau se déplace à gauche de 2 pixels
    EndIf
    
    If KeyboardPushed(#PB_Key_Right) And ShipX < ScreenWidth() - SpriteWidth(Ship)
      ShipX + 2 ;Le vaisseau se déplace à droite de 2 pixels
    EndIf
    
    ;Un tir est effectué avec la touche Espace
    ;Le tir doit être autorisé 
    If KeyboardPushed(#PB_Key_Space) And ShootAuthorization = #True
      ;On ajoute ce tir dans la liste des tirs du joueur PlayerShoots() 
      AddElement(PlayerShoots())
      
      ;Chaque tir part du milieu du vaisseau
      ;Création du nouveau sprite de tir à partir du sprite Shoot
      PlayerShoots()\Sprite = CopySprite(Shoot, #PB_Any) 
      
      ;Le nouveau tir est effectuté à partir du vaisseau
      PlayerShoots()\x = ShipX + SpriteWidth(Ship)/2 - SpriteWidth(PlayerShoots()\Sprite)/2
      PlayerShoots()\y = 500
      
      ShootTime = ElapsedMilliseconds()
    EndIf  
    
    ;Un tir est autorisé tout les 300 Millisecondes
    If ElapsedMilliseconds() - ShootTime > 300
      ShootAuthorization = #True
    Else
      ShootAuthorization = #False 
    EndIf
  EndIf
  
  ; 4 - Déplacement de l'ennemi
  ;     Pour cet exercice, l'ennemi se déplace de 2 pixels à droite ou à gauche
  ;     L'ennemi doit etre encore en vie (EnemyLife > 0)
  ;     L'ennemi ne doit pas sortir des limites gauche et droite de la surface de jeu
  If EnemyLife > 0
    If EnemyX < 0  Or  EnemyX > ScreenWidth() - SpriteWidth(Enemy) 
      EnemyDirection * -1 ;Direction sera égale alternativement à 1 ou -1
    EndIf
    
    EnemyX - 2 * EnemyDirection
    
    ;L'ennemi tire de façon aléatoire
    If Random(50, 1) = 1
      ;On ajoute ce tir dans la liste des tirs de l'ennemi EnemyShoots()
      AddElement(EnemyShoots())
      
      ;Création du nouveau sprite de tir à partir du sprite Shoot
      EnemyShoots()\Sprite = CopySprite(Shoot, #PB_Any) 
      
      ;Le nouveau tir est effectuté à partir du milieu bas de l'ennemi 
      EnemyShoots()\x = EnemyX + SpriteWidth(Enemy)/2 - SpriteWidth(EnemyShoots()\Sprite)/2
      EnemyShoots()\y = EnemyY + SpriteHeight(Enemy)
    EndIf
  EndIf 
  
  ; 5 - Inversion des buffers d'affichage  
  FlipBuffers()
  
Until KeyboardPushed(#PB_Key_Escape) ;La touche Escape permet de quitter le jeu
; IDE Options = PureBasic 5.42 LTS (Windows - x86)
; CursorPosition = 130
; FirstLine = 106
; EnableUnicode
; EnableXP