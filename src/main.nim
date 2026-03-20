import std/[strformat]
import raylib
import world
import player

const
  ScreenWidth = 1280
  ScreenHeight = 720
  ReachDistance = 6.0'f32

proc drawCrosshair() =
  let cx = getScreenWidth() div 2
  let cy = getScreenHeight() div 2
  drawLine(cx - 8, cy, cx + 8, cy, BLACK)
  drawLine(cx, cy - 8, cx, cy + 8, BLACK)

proc drawSelection(hit: BlockHit) =
  if not hit.found:
    return
  drawCubeWires(hit.target.toWorldPos(), 1.02'f32, 1.02'f32, 1.02'f32, YELLOW)

proc updateHotbarSelection(player: var Player) =
  if isKeyPressed(One): player.selectedBlock = 2
  if isKeyPressed(Two): player.selectedBlock = 3
  if isKeyPressed(Three): player.selectedBlock = 4
  if isKeyPressed(Four): player.selectedBlock = 1

proc main() =
  initWindow(ScreenWidth, ScreenHeight, "nimcraft - minimal voxel sandbox")
  defer: closeWindow()

  disableCursor()
  setTargetFPS(144)

  var
    gameWorld: World
    player = initPlayer()

  gameWorld.generateFlatWorld()

  while not windowShouldClose():
    let dt = getFrameTime()
    updateHotbarSelection(player)
    updatePlayer(player, gameWorld, dt)

    let camera = player.makeCamera()
    let hit = gameWorld.raycast(player.eyePosition(), player.lookDirection(), ReachDistance)

    if isMouseButtonPressed(Left):
      if hit.found and hit.target.y > 0:
        gameWorld.setBlock(hit.target.x, hit.target.y, hit.target.z, 0)

    if isMouseButtonPressed(Right):
      if hit.found:
        let place = hit.previous
        if inBounds(place.x, place.y, place.z) and not gameWorld.isSolid(place.x, place.y, place.z):
          gameWorld.setBlock(place.x, place.y, place.z, player.selectedBlock)

    beginDrawing()
    defer: endDrawing()

    clearBackground(Color(r: 186, g: 223, b: 255, a: 255))

    beginMode3D(camera)
    gameWorld.draw()
    drawSelection(hit)
    drawGrid(32, 1.0'f32)
    endMode3D()

    drawRectangle(12, 12, 340, 86, fade(RAYWHITE, 0.85'f32))
    drawText("WASD move  SPACE jump  Mouse look", 24, 22, 20, BLACK)
    drawText("LMB break  RMB place  1-4 select block", 24, 46, 20, BLACK)
    drawText(&"Block: {player.selectedBlock}   FPS: {getFPS()}", 24, 70, 20, DARKGRAY)
    drawCrosshair()

when isMainModule:
  main()
