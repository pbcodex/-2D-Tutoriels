;Invader

;
;Objectif de cet exercice
;   Afficher un vaisseau en bas de l'ecran
;   Afficher des ennemis façon Space Invaders en haut de l'ecran
;   Déplacer les ennemis de hauts en bas
;
;   Déplacer le vaisseau avec les touches gauche et droite du clavier
;   Effectuer des tirs avec la touche espace
;   
;   Régle 
;     Chaque ennemi a 5 vies

EnableExplicit

Enumeration Window
  #MainForm
EndEnumeration

;Structure d'un sprite qui servira pour le vaisseau, les ennemis et les tirs.
Structure NewSprite
  Sprite.i    ;Identifiant du sprite 
  x.i         ;Position x du sprite
  y.i         ;Position y du sprite
  life.i      ;Nombre de vies
EndStructure

;Vaisseau 
Global Ship.NewSprite

;Stockage des ennemis dans une liste chainées. Model d'ennemi et direction à prendre 
Global NewList Enemies.NewSprite(), ModelEnemy.i, Direction.i = 1 ;(-1 vers la gauche, 1 vers la droite, 0 fin du jeu)

;Stockage des tirs dans une liste chainée
Global NewList PlayerShoots.NewSprite(), ModelShoot, ShootTime, ShootAuthorization = #True 

;Evenements fenêtre, Rangée, Colonne.
Global Event, Row, Col

;Dossier média
Global FolderImages.s = "assets\/images\/"

;Initialisation de l'environnement 2D
If Not (InitSprite() And InitKeyboard())
  Debug "Ooops souci"
  End
EndIf

;Creation de la surface de jeu
OpenWindow(#MainForm, 0, 0, 800, 600, "Style Space Invaders", #PB_Window_SystemMenu|#PB_Window_ScreenCentered)
OpenWindowedScreen(WindowID(#MainForm), 0, 0, 800, 600)

;-Chargement des sprites
UsePNGImageDecoder()

;Création du vaisseau
Ship\Sprite  = LoadSprite(#PB_Any, FolderImages + "ship.png", #PB_Sprite_AlphaBlending)
Ship\x = 350
Ship\y = 500
Ship\life = 5

;Création des ennemis à partir du model d'ennemi
ModelEnemy = LoadSprite(#PB_Any, FolderImages + "enemy.png", #PB_Sprite_AlphaBlending)

For Row = 1 To 3 ; 3 rangées 
  For Col = 1 To 5 ; 5 colonnes
    AddElement(Enemies()) 
    With Enemies()
      \Sprite = CopySprite(ModelEnemy, #PB_Any)
      \x      = Col * 120
      \y      = Row  * 120
      \life   = 5
    EndWith 
  Next
Next

;Création du model de tir
ModelShoot = LoadSprite(#PB_Any, FolderImages + "shoot.png")

;-Boucle evenementielle
Repeat  ;Evenement du jeu
  Repeat;Evenement window
    Event = WindowEvent()
    Select Event    
      Case #PB_Event_CloseWindow
        End
    EndSelect  
  Until Event=0
  
  ;Effacer l'ecran avec une couleur avant d'afficher les sprites
  ClearScreen(RGB(0, 0, 0)) ;Commenter pour voir ce qu'il se passe
  
  ;-Affichage du vaisseau 
  DisplayTransparentSprite(Ship\Sprite, Ship\x  , Ship\y)
  
  ;-Affichage des ennemis
  ForEach Enemies()    
    
    ;Déplacement d'un ennemie de 1 pixel à gauche ou à droite
    ;Tout va dépendre de la direction horizontale qui est égale à -1 (A gauche) ou  1 (A droite)
    ;Si Direction = 0, alors fin du jeu.
    If Direction <> 0 
      Enemies()\x + 1 * Direction
      
      ;Si un ennemie atteint le bord droit ou gauche de la surface de jeu
      ;La direction change et tous les ennemis descendent de 10 pixels.
      If Enemies()\x = 0 Or Enemies()\x > ScreenWidth() - SpriteWidth(Enemies()\Sprite)
        
        ;La direction change
        Direction * -1
        
        ;STOP!! Gardons en mémoire la position de l'élement courant afin de revenir dessus.
        ;L'instruction PushListPosition() permet de mémoriser la position de l'élément de la liste des ennemis.
        PushListPosition(Enemies()) 
        
        ;On va devoir parcourir une nouvelle fois la liste chainée des ennemis.
        ;Chaque ennemi descend de 10 pixels
        ForEach Enemies()
          Enemies()\y + 10
        Next
        
        ;Retour à la position mémoriser afin de continuer le traitement de chaque sprite. 
        ;L'instruction PopListPosition() permet pointer sur l'élémement mémorisé de la liste des ennemis.
        PopListPosition(Enemies())        
      EndIf
      
      ;Si un énnemi atteint le vaisseau alors : la fin du jeu 
      If SpriteCollision(Ship\Sprite, Ship\x, Ship\y, Enemies()\Sprite, Enemies()\x, Enemies()\y - 10)
        Ship\life = 0
        Direction = 0
      EndIf
    EndIf 
    DisplayTransparentSprite(Enemies()\Sprite, Enemies()\x, Enemies()\y)
  Next
  
  ;-Affichage des shoots
  ForEach PlayerShoots()
    PlayerShoots()\y - 2 ;Chaque shoot remonte de deux  pixels
    
    ;Ce tir sort t'il en haut de l'écran ?
    If PlayerShoots()\y < 0
      FreeSprite(PlayerShoots()\Sprite) ;Destruction du tir
      DeleteElement(PlayerShoots(), #True) ;Destruction des information du tir
    Else
      
      DisplaySprite(PlayerShoots()\Sprite, PlayerShoots()\x, PlayerShoots()\y)
      
      ;Il y a t'il collision entre un shoot et un ennemi
      ForEach Enemies()
        If ListSize(PlayerShoots())<>0 
          If SpriteCollision(Enemies()\Sprite, Enemies()\x, Enemies()\y, PlayerShoots()\Sprite, PlayerShoots()\x, PlayerShoots()\y)
            FreeSprite(PlayerShoots()\Sprite) ;Destruction du sprite représentant le tir
            DeleteElement(PlayerShoots(), #True) ;Suppression de l'élément de la liste chainée correspondant au tir
            
            ;Diminution du nombre de vie ou destruction de l'ennemi
            Enemies()\life - 1
            
            If Enemies()\life = 0
              FreeSprite(Enemies()\Sprite)    
              DeleteElement(Enemies(), #True) 
            EndIf
          EndIf
        EndIf 
      Next
    EndIf
  Next 
  
  ;- Une touche du clavier est préssée
  ExamineKeyboard()
  
  ;Déplacement du vaisseau avec les touches droite ou gauche
  ;Le vaisseau ne doit pas sortir des limites gauche et droite de la surface du jeu
  If KeyboardPushed(#PB_Key_Left) And Ship\x > 0 
    Ship\x - 2 ;Le vaisseau se déplace à gauche de 2 pixels
  EndIf
  
  If KeyboardPushed(#PB_Key_Right) And Ship\x < ScreenWidth() - SpriteWidth(Ship\Sprite)
    Ship\x + 2 ;Le vaisseau se déplace à droite de 2 pixels
  EndIf
  
  ;Un tir est effectué avec la touche Espace
  ;Le tir doit être autorisé 
  If KeyboardPushed(#PB_Key_Space) And ShootAuthorization = #True
    
    ;On ajoute ce tir dans la liste chainée des tirs PlayerShoots() 
    AddElement(PlayerShoots())
    
    ;Chaque tir est lancé du milieu du vaisseau
    ;Création du nouveau sprite de tir à partir du sprite Shoot
    PlayerShoots()\Sprite = CopySprite(ModelShoot, #PB_Any) 
    
    ;Le nouveau tir est effectuté à partir du vaisseau
    PlayerShoots()\x = Ship\x + SpriteWidth(Ship\Sprite)/2 - SpriteWidth(PlayerShoots()\Sprite)/2
    PlayerShoots()\y = 500
    
    ;Mémorisation de l'heure de tir en miilisecondes
    ShootTime = ElapsedMilliseconds()
  EndIf  
  
  ;Un tir est autorisé tout les 300 Millisecondes
  If ElapsedMilliseconds() - ShootTime > 300
    ShootAuthorization = #True 
  Else
    ShootAuthorization = #False 
  EndIf
  
  ;Inversion des buffers d'affichage  
  FlipBuffers()
  
Until KeyboardPushed(#PB_Key_Escape) ;La touche Escape permet de quitter le jeu
; IDE Options = PureBasic 5.42 LTS (Windows - x86)
; CursorPosition = 29
; FirstLine = 29
; EnableUnicode
; EnableXP