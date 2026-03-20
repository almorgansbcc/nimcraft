import std/[math]
import raylib
import world

const
  PlayerRadius* = 0.3'f32
  EyeHeight* = 1.62'f32
  PlayerHeight* = 1.8'f32
  Gravity = 28.0'f32
  MoveSpeed = 5.8'f32
  JumpSpeed = 8.5'f32
  MouseSensitivity = 0.0025'f32
  MaxLookPitch = 1.5'f32
  DegToRad32 = PI.float32 / 180.0'f32

type
  Player* = object
    position*: Vector3
    velocity*: Vector3
    yaw*: float32
    pitch*: float32
    onGround*: bool
    selectedBlock*: BlockId

func vec3(x, y, z: float32): Vector3 =
  Vector3(x: x, y: y, z: z)

func upVec(): Vector3 =
  vec3(0, 1, 0)

func vadd(a, b: Vector3): Vector3 =
  vec3(a.x + b.x, a.y + b.y, a.z + b.z)

func vsub(a, b: Vector3): Vector3 =
  vec3(a.x - b.x, a.y - b.y, a.z - b.z)

func vscale(v: Vector3; s: float32): Vector3 =
  vec3(v.x * s, v.y * s, v.z * s)

func vlength(v: Vector3): float32 =
  sqrt(v.x * v.x + v.y * v.y + v.z * v.z)

func vnormalize(v: Vector3): Vector3 =
  let len = vlength(v)
  if len <= 0.0001'f32:
    vec3(0, 0, 0)
  else:
    vscale(v, 1.0'f32 / len)

func signf(value: float32): float32 =
  if value > 0: 1'f32
  elif value < 0: -1'f32
  else: 0'f32

proc initPlayer*(): Player =
  Player(
    position: vec3(WorldWidth.float32 / 2'f32, 4.0'f32, WorldDepth.float32 / 2'f32),
    velocity: vec3(0, 0, 0),
    yaw: -90'f32 * DegToRad32,
    pitch: -10'f32 * DegToRad32,
    onGround: false,
    selectedBlock: 2
  )

func eyePosition*(player: Player): Vector3 =
  vadd(player.position, vec3(0, EyeHeight, 0))

func lookDirection*(player: Player): Vector3 =
  vnormalize(vec3(
    cos(player.pitch) * cos(player.yaw),
    sin(player.pitch),
    cos(player.pitch) * sin(player.yaw)
  ))

func hasCollision(world: World; pos: Vector3): bool =
  let minX = floor(pos.x - PlayerRadius).int
  let maxX = floor(pos.x + PlayerRadius).int
  let minY = floor(pos.y).int
  let maxY = floor(pos.y + PlayerHeight).int
  let minZ = floor(pos.z - PlayerRadius).int
  let maxZ = floor(pos.z + PlayerRadius).int

  for y in minY .. maxY:
    for z in minZ .. maxZ:
      for x in minX .. maxX:
        if world.isSolid(x, y, z):
          return true
  false

proc moveAxis(player: var Player; world: World; delta: float32; axis: char) =
  var nextPos = player.position
  case axis
  of 'x':
    nextPos.x += delta
  of 'y':
    nextPos.y += delta
  of 'z':
    nextPos.z += delta
  else:
    discard

  if hasCollision(world, nextPos):
    case axis
    of 'x':
      player.velocity.x = 0
    of 'y':
      if delta < 0:
        player.onGround = true
      player.velocity.y = 0
    of 'z':
      player.velocity.z = 0
    else:
      discard
  else:
    case axis
    of 'x': player.position.x = nextPos.x
    of 'y': player.position.y = nextPos.y
    of 'z': player.position.z = nextPos.z
    else: discard

proc updatePlayer*(player: var Player; world: World; dt: float32) =
  let wasOnGround = player.onGround
  let mouseDelta = getMouseDelta()
  player.yaw += mouseDelta.x * MouseSensitivity
  player.pitch -= mouseDelta.y * MouseSensitivity
  player.pitch = clamp(player.pitch, -MaxLookPitch, MaxLookPitch)

  var wish = vec3(0, 0, 0)
  let forward = vnormalize(vec3(cos(player.yaw), 0, sin(player.yaw)))
  let right = vec3(-forward.z, 0, forward.x)

  if isKeyDown(W): wish = vadd(wish, forward)
  if isKeyDown(S): wish = vsub(wish, forward)
  if isKeyDown(D): wish = vadd(wish, right)
  if isKeyDown(A): wish = vsub(wish, right)

  if vlength(wish) > 0:
    wish = vscale(vnormalize(wish), MoveSpeed)

  player.velocity.x = wish.x
  player.velocity.z = wish.z

  if isKeyPressed(Space) and wasOnGround:
    player.velocity.y = JumpSpeed
  else:
    player.velocity.y -= Gravity * dt

  player.onGround = false

  player.moveAxis(world, player.velocity.x * dt, 'x')
  player.moveAxis(world, player.velocity.y * dt, 'y')
  player.moveAxis(world, player.velocity.z * dt, 'z')

  if player.position.y < -20:
    player = initPlayer()

proc makeCamera*(player: Player): Camera3D =
  Camera3D(
    position: player.eyePosition(),
    target: vadd(player.eyePosition(), player.lookDirection()),
    up: upVec(),
    fovy: 70.0'f32,
    projection: Perspective
  )
