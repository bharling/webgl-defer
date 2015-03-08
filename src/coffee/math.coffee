# add some missing mat3 stuff

mat3.makeTranslation = (tx, ty) ->
  tm = mat3.create()
  mat3.identity tm
  tm[6] = tx
  tm[7] = ty
  tm
  
mat3.makeRotation = (radians) ->
  c = Math.cos(radians)
  s = Math.sin(radians)
  
  rm = mat3.create()
  rm.identity()
  rm[0] = c
  rm[1] = -s
  rm[2] = 0
  rm[3] = s
  rm[4] = c
  rm[5] = 0
  rm[6] = 0
  rm[7] = 0
  rm[8] = 1
  rm

mat3.makeProjection = (w, h) ->
  pm = mat3.create()
  mat3.identity pm
  pm[0] = 2.0 / w
  pm[1] = 0
  pm[2] = 0
  pm[3] = 0
  pm[4] = -2.0 / h
  pm[5] = 0
  pm[6] = -1
  pm[7] = 1
  pm[8] = 1
  pm  

mat3.makeScale = (sx, sy) ->
  sm = mat3.create()
  mat3.identity sm
  sm[0] = sx
  sm[4] = sy
  sm
  
mat3.multiply = (a,b) ->
  # multiply a by b
  a00 = a[0*3+0]
  a01 = a[0*3+1]
  a02 = a[0*3+2]
  a10 = a[1*3+0]
  a11 = a[1*3+1]
  a12 = a[1*3+2]
  a20 = a[2*3+0]
  a21 = a[2*3+1]
  a22 = a[2*3+2]
  b00 = b[0*3+0]
  b01 = b[0*3+1]
  b02 = b[0*3+2]
  b10 = b[1*3+0]
  b11 = b[1*3+1]
  b12 = b[1*3+2]
  b20 = b[2*3+0]
  b21 = b[2*3+1]
  b22 = b[2*3+2]
  
  ret = mat3.create()
  ret[0] = a00 * b00 + a01 * b10 + a02 * b20
  ret[1] = a00 * b01 + a01 * b11 + a02 * b21
  ret[2] = a00 * b02 + a01 * b12 + a02 * b22
  ret[3] = a10 * b00 + a11 * b10 + a12 * b20
  ret[4] = a10 * b01 + a11 * b11 + a12 * b21
  ret[5] = a10 * b02 + a11 * b12 + a12 * b22
  ret[6] = a20 * b00 + a21 * b10 + a22 * b20
  ret[7] = a20 * b01 + a21 * b11 + a22 * b21
  ret[8] = a20 * b02 + a21 * b12 + a22 * b22
  ret

  
