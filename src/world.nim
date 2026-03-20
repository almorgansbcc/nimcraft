import std/[math]
import raylib

const
  WorldWidth* = 32
  WorldDepth* = 32
  WorldHeight* = 16

type
  BlockId* = uint8

  IVec3* = object
    x*, y*, z*: int

  BlockHit* = object
    found*: bool
    target*, previous*: IVec3

  World* = object
    blocks: array[WorldWidth * WorldDepth * WorldHeight, BlockId]

func vec3*(x, y, z: float32): Vector3 =
  Vector3(x: x, y: y, z: z)

func vadd(a, b: Vector3): Vector3 =
  vec3(a.x + b.x, a.y + b.y, a.z + b.z)

func vscale(v: Vector3; s: float32): Vector3 =
  vec3(v.x * s, v.y * s, v.z * s)

func ivec3*(x, y, z: int): IVec3 =
  IVec3(x: x, y: y, z: z)

func toWorldPos*(cell: IVec3): Vector3 =
  vec3(cell.x.float32 + 0.5'f32, cell.y.float32 + 0.5'f32, cell.z.float32 + 0.5'f32)

func inBounds*(x, y, z: int): bool =
  x >= 0 and x < WorldWidth and
  y >= 0 and y < WorldHeight and
  z >= 0 and z < WorldDepth

func indexOf(x, y, z: int): int =
  x + z * WorldWidth + y * WorldWidth * WorldDepth

proc getBlock*(world: World; x, y, z: int): BlockId =
  if inBounds(x, y, z):
    world.blocks[indexOf(x, y, z)]
  else:
    0'u8

proc setBlock*(world: var World; x, y, z: int; blockId: BlockId) =
  if inBounds(x, y, z):
    world.blocks[indexOf(x, y, z)] = blockId

proc isSolid*(world: World; x, y, z: int): bool =
  world.getBlock(x, y, z) != 0

proc generateFlatWorld*(world: var World) =
  for z in 0 ..< WorldDepth:
    for x in 0 ..< WorldWidth:
      world.setBlock(x, 0, z, 3)
      world.setBlock(x, 1, z, 2)
      if ((x + z) mod 11) == 0:
        world.setBlock(x, 2, z, 4)

proc blockColor*(blockId: BlockId): Color =
  case blockId
  of 1'u8: Color(r: 160, g: 160, b: 160, a: 255)
  of 2'u8: Color(r: 110, g: 178, b: 70, a: 255)
  of 3'u8: Color(r: 120, g: 84, b: 58, a: 255)
  of 4'u8: Color(r: 194, g: 182, b: 128, a: 255)
  else: BLANK

proc draw*(world: World) =
  for y in 0 ..< WorldHeight:
    for z in 0 ..< WorldDepth:
      for x in 0 ..< WorldWidth:
        let blockId = world.getBlock(x, y, z)
        if blockId == 0:
          continue

        let pos = vec3(x.float32 + 0.5'f32, y.float32 + 0.5'f32, z.float32 + 0.5'f32)
        let color = blockColor(blockId)
        drawCube(pos, 1.0'f32, 1.0'f32, 1.0'f32, color)

        if not world.isSolid(x + 1, y, z) or
           not world.isSolid(x - 1, y, z) or
           not world.isSolid(x, y + 1, z) or
           not world.isSolid(x, y - 1, z) or
           not world.isSolid(x, y, z + 1) or
           not world.isSolid(x, y, z - 1):
          drawCubeWires(pos, 1.0'f32, 1.0'f32, 1.0'f32, Color(r: 30, g: 30, b: 30, a: 255))

proc raycast*(world: World; origin, direction: Vector3; maxDistance: float32): BlockHit =
  var
    distance = 0.0'f32
    previous = ivec3(floor(origin.x).int, floor(origin.y).int, floor(origin.z).int)
  let step = 0.05'f32

  while distance <= maxDistance:
    let point = vadd(origin, vscale(direction, distance))
    let cell = ivec3(floor(point.x).int, floor(point.y).int, floor(point.z).int)
    if world.isSolid(cell.x, cell.y, cell.z):
      return BlockHit(found: true, target: cell, previous: previous)
    previous = cell
    distance += step

  BlockHit(found: false)
