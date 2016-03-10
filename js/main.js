
/*
 * @fileoverview DFIR Engine - Deferred WebGL render engine
 * @author Ben Harling
 * @version 0.7
 *

Copyright (c) 2016, Ben Harling

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
 */

(function() {
  var DFIR, DebugView, InertialValue, InertialVector, Pointer, VertexFormat, buildProgram, buildProgramFromStrings, buildShaderProgram, debug_textures, exports, fs_quad_fragment_shader, fs_quad_vertex_shader, getShader, getShaderParams, initTexture, keymap, keys, loadJSON, loadResource, loadShaderAjax, loadTexture, mergeVertices, name, pixelsToClip, shader, shader_type_enums, stringFromUint, tCache, texturedebug, triangle, value,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  exports = typeof exports !== 'undefined' ? exports : window;

  DFIR = {};

  DFIR.currentId = 0;

  DFIR.nextId = function() {
    return DFIR.currentId++;
  };

  exports.DFIR = DFIR;

  mat3.makeTranslation = function(tx, ty) {
    var tm;
    tm = mat3.create();
    mat3.identity(tm);
    tm[6] = tx;
    tm[7] = ty;
    return tm;
  };

  mat3.makeRotation = function(radians) {
    var c, rm, s;
    c = Math.cos(radians);
    s = Math.sin(radians);
    rm = mat3.create();
    rm.identity();
    rm[0] = c;
    rm[1] = -s;
    rm[2] = 0;
    rm[3] = s;
    rm[4] = c;
    rm[5] = 0;
    rm[6] = 0;
    rm[7] = 0;
    rm[8] = 1;
    return rm;
  };

  mat3.makeProjection = function(w, h) {
    var pm;
    pm = mat3.create();
    mat3.identity(pm);
    pm[0] = 2.0 / w;
    pm[1] = 0;
    pm[2] = 0;
    pm[3] = 0;
    pm[4] = -2.0 / h;
    pm[5] = 0;
    pm[6] = -1;
    pm[7] = 1;
    pm[8] = 1;
    return pm;
  };

  mat3.makeScale = function(sx, sy) {
    var sm;
    sm = mat3.create();
    mat3.identity(sm);
    sm[0] = sx;
    sm[4] = sy;
    return sm;
  };

  mat3.multiply = function(a, b) {
    var a00, a01, a02, a10, a11, a12, a20, a21, a22, b00, b01, b02, b10, b11, b12, b20, b21, b22, ret;
    a00 = a[0 * 3 + 0];
    a01 = a[0 * 3 + 1];
    a02 = a[0 * 3 + 2];
    a10 = a[1 * 3 + 0];
    a11 = a[1 * 3 + 1];
    a12 = a[1 * 3 + 2];
    a20 = a[2 * 3 + 0];
    a21 = a[2 * 3 + 1];
    a22 = a[2 * 3 + 2];
    b00 = b[0 * 3 + 0];
    b01 = b[0 * 3 + 1];
    b02 = b[0 * 3 + 2];
    b10 = b[1 * 3 + 0];
    b11 = b[1 * 3 + 1];
    b12 = b[1 * 3 + 2];
    b20 = b[2 * 3 + 0];
    b21 = b[2 * 3 + 1];
    b22 = b[2 * 3 + 2];
    ret = mat3.create();
    ret[0] = a00 * b00 + a01 * b10 + a02 * b20;
    ret[1] = a00 * b01 + a01 * b11 + a02 * b21;
    ret[2] = a00 * b02 + a01 * b12 + a02 * b22;
    ret[3] = a10 * b00 + a11 * b10 + a12 * b20;
    ret[4] = a10 * b01 + a11 * b11 + a12 * b21;
    ret[5] = a10 * b02 + a11 * b12 + a12 * b22;
    ret[6] = a20 * b00 + a21 * b10 + a22 * b20;
    ret[7] = a20 * b01 + a21 * b11 + a22 * b21;
    ret[8] = a20 * b02 + a21 * b12 + a22 * b22;
    return ret;
  };

  pixelsToClip = function(pos) {
    var px, py;
    px = pos[0] / gl.viewportWidth;
    py = pos[1] / gl.viewportHeight;
    px = px * 2.0;
    py = py * 2.0;
    px -= 1.0;
    py -= 1.0;
    py *= -1.0;
    return [px, py];
  };

  DFIR.Buffer = (function() {
    function Buffer(data, itemSize, mode, type1) {
      this.itemSize = itemSize;
      this.mode = mode;
      this.type = type1;
      if (this.type == null) {
        this.type = gl.ARRAY_BUFFER;
      }
      this.buffer = gl.createBuffer();
      gl.bindBuffer(this.type, this.buffer);
      gl.bufferData(this.type, data, this.mode);
      this.numItems = data.length / this.itemSize;
    }

    Buffer.prototype.bind = function() {
      return gl.bindBuffer(this.type, this.buffer);
    };

    Buffer.prototype.get = function() {
      return this.buffer;
    };

    Buffer.prototype.release = function() {
      return gl.bindBuffer(this.type, null);
    };

    return Buffer;

  })();

  DFIR.Object2D = (function() {
    function Object2D() {}

    return Object2D;

  })();

  DFIR.Object3D = (function() {
    function Object3D() {
      this.position = vec3.create();
      this.scale = vec3.fromValues(1.0, 1.0, 1.0);
      this.rotation = quat.create();
      this.transform = mat4.create();
      this.transformDirty = true;
      this.normalMatrix = mat3.create();
      this.worldViewProjectionMatrix = mat4.create();
      this.children = [];
      this.visible = true;
      this.metallic = Math.random();
      this.roughness = Math.random();
      this.material = null;
      this.loaded = false;
    }

    Object3D.prototype.setMaterial = function(shader) {
      return this.material = shader;
    };

    Object3D.prototype.getWorldTransform = function() {
      if (this.transformDirty === true) {
        this.updateWorldTransform();
      }
      return this.transform;
    };

    Object3D.prototype.getNormalMatrix = function(camera, worldMatrix) {
      var temp;
      temp = mat4.create();
      mat4.multiply(temp, camera.getViewMatrix(), worldMatrix);
      mat3.normalFromMat4(this.normalMatrix, temp);
      return this.normalMatrix;
    };

    Object3D.prototype.draw = function(camera, worldMatrix) {
      if (!this.material || !this.loaded) {
        return;
      }
      this.material.use();
      this.update();
      if (worldMatrix == null) {
        worldMatrix = this.transform;
      }
      this.getNormalMatrix(camera, worldMatrix);
      mat4.multiply(this.worldViewProjectionMatrix, camera.getViewProjectionMatrix(), worldMatrix);
      this.setMatrixUniforms(this.worldViewProjectionMatrix, this.normalMatrix);
      this.bindTextures();
      gl.uniform1f(this.material.getUniform('roughness'), this.roughness);
      gl.uniform1f(this.material.getUniform('metallic'), this.metallic);
      gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.vertexIndexBuffer.get());
      return gl.drawElements(gl.TRIANGLES, this.vertexIndexBuffer.numItems, gl.UNSIGNED_SHORT, 0);
    };

    Object3D.prototype.bindTextures = function() {
      gl.activeTexture(gl.TEXTURE0);
      gl.bindTexture(gl.TEXTURE_2D, this.material.diffuseMap);
      gl.uniform1i(this.material.getUniform('diffuseTex'), 0);
      gl.activeTexture(gl.TEXTURE1);
      gl.bindTexture(gl.TEXTURE_2D, this.material.normalMap);
      return gl.uniform1i(this.material.getUniform('normalTex'), 1);
    };

    Object3D.prototype.setFloatUniform = function(name, val) {
      return gl.uniform1f(this.material.getUniform(name), val);
    };

    Object3D.prototype.setVec4Uniform = function(name, x, y, z, w) {
      return gl.uniform4f(this.material.getUniform(name), x, y, z, w);
    };

    Object3D.prototype.setMatrixUniforms = function(wvpMatrix, normalMatrix) {
      if (!this.material) {
        return null;
      }
      gl.uniformMatrix4fv(this.material.getUniform('uWorldViewProjectionMatrix'), false, wvpMatrix);
      gl.uniformMatrix3fv(this.material.getUniform('uNormalMatrix'), false, normalMatrix);
      return this.setFloatUniform('farClip', camera.far);
    };

    Object3D.prototype.updateWorldTransform = function(parentTransform) {
      if (parentTransform == null) {
        parentTransform = null;
      }
      mat4.identity(this.transform);
      mat4.translate(this.transform, this.transform, this.position);
      mat4.scale(this.transform, this.transform, this.scale);
      this.transformDirty = false;
    };

    Object3D.prototype.setPosition = function(pos) {
      vec3.copy(this.position, pos);
      return this.transformDirty = true;
    };

    Object3D.prototype.setScale = function(s) {
      vec3.copy(this.scale, s);
      return this.transformDirty = true;
    };

    Object3D.prototype.translate = function(vec) {
      vec3.translate(this.position, vec);
      return this.transformDirty = true;
    };

    Object3D.prototype.rotateX = function(rad) {
      quat.rotateX(this.rotation, this.rotation, rad);
      return this.transformDirty = true;
    };

    Object3D.prototype.rotateY = function(rad) {
      quat.rotateY(this.rotation, this.rotation, rad);
      return this.transformDirty = true;
    };

    Object3D.prototype.rotateZ = function(rad) {
      quat.rotateZ(this.rotation, this.rotation, rad);
      return this.transformDirty = true;
    };

    Object3D.prototype.visit = function(func) {
      var c, l, len, ref, results;
      if (!this.visible) {
        return;
      }
      func(this);
      ref = this.children;
      results = [];
      for (l = 0, len = ref.length; l < len; l++) {
        c = ref[l];
        results.push(c.visit(func));
      }
      return results;
    };

    Object3D.prototype.update = function() {
      if (this.transformDirty) {
        mat4.fromRotationTranslationScale(this.transform, this.rotation, this.position, this.scale);
        return this.transformDirty = false;
      }
    };

    Object3D.prototype.addChild = function(childObject) {
      return this.children.push(childObject);
    };

    Object3D.prototype.removeChild = function(childObject) {
      return this.children.remove(childObject);
    };

    return Object3D;

  })();

  DFIR.Scene = (function(superClass) {
    extend(Scene, superClass);

    function Scene() {
      return Scene.__super__.constructor.apply(this, arguments);
    }

    null;

    return Scene;

  })(DFIR.Object3D);

  DFIR.MeshObject = (function(superClass) {
    extend(MeshObject, superClass);

    function MeshObject(mesh) {
      this.mesh = mesh;
      MeshObject.__super__.constructor.call(this);
    }

    MeshObject.prototype.bind = function() {
      var normalsAttrib, positionAttrib, texCoordsAttrib;
      if (!this.material || !this.material.diffuseMapLoaded || !this.material.normalMapLoaded || !this.mesh.ready) {
        return false;
      }
      this.material.use();
      positionAttrib = this.material.getAttribute('aVertexPosition');
      texCoordsAttrib = this.material.getAttribute('aVertexTextureCoords');
      normalsAttrib = this.material.getAttribute('aVertexNormal');
      return this.mesh.bind(positionAttrib, normalsAttrib, texCoordsAttrib);
    };

    MeshObject.prototype.release = function() {
      return gl.bindBuffer(gl.ARRAY_BUFFER, null);
    };

    MeshObject.prototype.draw = function(camera, worldMatrix) {
      if (!this.material || !this.mesh.ready) {
        return;
      }
      this.material.use();
      this.update();
      if (worldMatrix == null) {
        worldMatrix = this.transform;
      }
      this.getNormalMatrix(camera, worldMatrix);
      mat4.multiply(this.worldViewProjectionMatrix, camera.getViewProjectionMatrix(), worldMatrix);
      this.setMatrixUniforms(this.worldViewProjectionMatrix, this.normalMatrix);
      this.bindTextures();
      gl.uniform1f(this.material.getUniform('roughness'), this.roughness);
      gl.uniform1f(this.material.getUniform('metallic'), this.metallic);
      return gl.drawElements(gl.TRIANGLES, this.mesh.indexLength, gl.UNSIGNED_SHORT, 0);
    };

    return MeshObject;

  })(DFIR.Object3D);

  mergeVertices = function(vertices, faces) {
    var changes, i, key, l, precision, precisionPoints, ref, results, unique, v, verticesMap;
    verticesMap = {};
    unique = [];
    changes = [];
    precisionPoints = 4;
    precision = Math.pow(10, precisionPoints);
    results = [];
    for (i = l = 0, ref = vertices.length; l < ref; i = l += 1) {
      v = vertices[i];
      key = (Math.round(v[0] * precision)) + "_" + (Math.round(v[1] * precision)) + "_" + (Math.round(v[2] * precision));
      if (verticesMap[key] != null) {
        results.push(changes[i] = changes[verticesMap[key]]);
      } else {
        verticesMap[key] = i;
        unique.push(vertices[i]);
        results.push(changes[i] = unique.length - 1);
      }
    }
    return results;
  };

  DFIR.Face = (function() {
    function Face(a1, b1, c1) {
      this.a = a1;
      this.b = b1;
      this.c = c1;
    }

    return Face;

  })();

  DFIR.Geometry = (function() {
    function Geometry() {
      this.indices = [];
      this.faces = [];
      this.vertices = [];
      this.normals = [];
      this.texCoords = [[]];
      this.vertexBuffer = null;
      this.texCoordBuffers = [];
      this.indexBuffer = null;
      this.normalBuffer = null;
    }

    return Geometry;

  })();

  DFIR.Geometry.meshCache = {};

  DFIR.Plane = (function(superClass) {
    extend(Plane, superClass);

    function Plane(size, detail) {
      var hs;
      if (detail == null) {
        detail = 1;
      }
      hs = size / 2;
      this.vertices = [-hs, 0, 0, hs, 0, 0, hs, 0, hs, -hs, 0, hs];
      this.indexes = [];
    }

    return Plane;

  })(DFIR.Geometry);

  DFIR.CubeGeometry = (function(superClass) {
    extend(CubeGeometry, superClass);

    function CubeGeometry(size, detail) {
      if (detail == null) {
        detail = 1;
      }
      CubeGeometry.__super__.constructor.call(this);
    }

    return CubeGeometry;

  })(DFIR.Geometry);

  DFIR.SphereGeometry = (function(superClass) {
    extend(SphereGeometry, superClass);

    function SphereGeometry(rings) {
      SphereGeometry.__super__.constructor.call(this);
    }

    return SphereGeometry;

  })(DFIR.Geometry);

  VertexFormat = {
    Position: 0x0001,
    UV: 0x0002,
    UV2: 0x0004,
    Normal: 0x0008,
    Color: 0x0010
  };

  stringFromUint = function(num) {
    var s;
    s = "";
    s += String.fromCharCode(num & 0xff);
    s += String.fromCharCode((num >> 8) & 0xff);
    s += String.fromCharCode((num >> 16) & 0xff);
    s += String.fromCharCode((num >> 24) & 0xff);
    return s;
  };

  DFIR.Mesh = (function() {
    function Mesh(url) {
      this.load(url);
      this.ready = false;
    }

    Mesh.prototype.load = function(url) {
      var modelComplete, modelXHR, self, vertComplete, vertXHR;
      self = this;
      vertComplete = false;
      modelComplete = false;
      vertXHR = new XMLHttpRequest();
      vertXHR.open('GET', url);
      vertXHR.responseType = 'arraybuffer';
      vertXHR.onload = function() {
        var arrays;
        arrays = self.parseBinary(this.response);
        self.compileBuffers(arrays);
        vertComplete = true;
        self.ready = true;
        if (self.modelComplete) {
          return something;
        }
      };
      vertXHR.send(null);
      return modelXHR = new XMLHttpRequest();
    };

    Mesh.prototype.parseBinary = function(data) {
      var header, indexLength, indices, magic, vertLength, vertices;
      header = new Uint32Array(data, 0, 3);
      magic = header[0], vertLength = header[1], indexLength = header[2];
      magic = stringFromUint(magic);
      if (magic !== 'DFIR') {
        console.error("Magic String, she no match");
      }
      console.log(vertLength + " vertices, " + indexLength + " indices");
      vertices = new Float32Array(data, 3 * 4, vertLength);
      indices = new Uint16Array(data, (3 * 4) + (vertLength * 4), indexLength);
      this.vertexLength = vertLength / 8;
      this.indexLength = indexLength;
      console.log(indices, indexLength);
      return [vertices, indices];
    };

    Mesh.prototype.parseJSON = function(data) {};

    Mesh.prototype.compileBuffers = function(arrays) {
      this.vertexBuffer = gl.createBuffer();
      gl.bindBuffer(gl.ARRAY_BUFFER, this.vertexBuffer);
      gl.bufferData(gl.ARRAY_BUFFER, arrays[0], gl.STATIC_DRAW);
      this.indexBuffer = gl.createBuffer();
      gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.indexBuffer);
      gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, arrays[1], gl.STATIC_DRAW);
      gl.bindBuffer(gl.ARRAY_BUFFER, null);
      gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null);
      return this.vertexStride = 32;
    };

    Mesh.prototype.bind = function(positionAttrib, normalsAttrib, uvAttrib) {
      if (!this.ready) {
        return false;
      }
      gl.bindBuffer(gl.ARRAY_BUFFER, this.vertexBuffer);
      gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.indexBuffer);
      gl.enableVertexAttribArray(positionAttrib);
      gl.vertexAttribPointer(positionAttrib, 3, gl.FLOAT, false, this.vertexStride, 0);
      gl.enableVertexAttribArray(normalsAttrib);
      gl.vertexAttribPointer(normalsAttrib, 3, gl.FLOAT, true, this.vertexStride, 12);
      gl.enableVertexAttribArray(uvAttrib);
      gl.vertexAttribPointer(uvAttrib, 2, gl.FLOAT, false, this.vertexStride, 24);
      return true;
    };

    return Mesh;

  })();

  loadJSON = function(url, callback) {
    var key, request;
    key = md5(url);
    if (DFIR.Geometry.meshCache[key] != null) {
      console.log('Not loading #{url}');
      callback(DFIR.Geometry.meshCache[key]);
      return;
    }
    request = new XMLHttpRequest();
    request.open('GET', url);
    request.onreadystatechange = function() {
      var result;
      if (request.readyState === 4) {
        result = JSON.parse(request.responseText);
        DFIR.Geometry.meshCache[key] = result;
        return callback(JSON.parse(request.responseText));
      }
    };
    return request.send();
  };

  DFIR.JSONGeometry = (function(superClass) {
    extend(JSONGeometry, superClass);

    function JSONGeometry(url) {
      this.parseThreeJSModel = bind(this.parseThreeJSModel, this);
      this.onDataLoaded = bind(this.onDataLoaded, this);
      JSONGeometry.__super__.constructor.call(this);
      loadJSON(url, this.onDataLoaded);
    }

    JSONGeometry.prototype.bind = function() {
      var normalsAttrib, positionAttrib, texCoordsAttrib;
      if (!this.material || !this.loaded || !this.material.diffuseMapLoaded || !this.material.normalMapLoaded) {
        return false;
      }
      this.material.use();
      positionAttrib = this.material.getAttribute('aVertexPosition');
      texCoordsAttrib = this.material.getAttribute('aVertexTextureCoords');
      normalsAttrib = this.material.getAttribute('aVertexNormal');
      gl.enableVertexAttribArray(positionAttrib);
      gl.bindBuffer(gl.ARRAY_BUFFER, this.vertexPositionBuffer.get());
      gl.vertexAttribPointer(positionAttrib, this.vertexPositionBuffer.itemSize, gl.FLOAT, false, 12, 0);
      gl.enableVertexAttribArray(texCoordsAttrib);
      gl.bindBuffer(gl.ARRAY_BUFFER, this.vertexTextureCoordBuffer.get());
      gl.vertexAttribPointer(texCoordsAttrib, this.vertexTextureCoordBuffer.itemSize, gl.FLOAT, false, 8, 0);
      gl.enableVertexAttribArray(normalsAttrib);
      gl.bindBuffer(gl.ARRAY_BUFFER, this.vertexNormalBuffer.get());
      gl.vertexAttribPointer(normalsAttrib, this.vertexNormalBuffer.itemSize, gl.FLOAT, false, 12, 0);
      return true;
    };

    JSONGeometry.prototype.release = function() {
      return gl.bindBuffer(gl.ARRAY_BUFFER, null);
    };

    JSONGeometry.prototype.onDataLoaded = function(data) {
      if (data.vertexPositions != null) {
        this.vertexPositionBuffer = new DFIR.Buffer(new Float32Array(data.vertexPositions), 3, gl.STATIC_DRAW);
        this.vertexTextureCoordBuffer = new DFIR.Buffer(new Float32Array(data.vertexTextureCoords), 2, gl.STATIC_DRAW);
        this.vertexNormalBuffer = new DFIR.Buffer(new Float32Array(data.vertexNormals), 3, gl.STATIC_DRAW);
        this.vertexIndexBuffer = new DFIR.Buffer(new Uint16Array(data.indices), 1, gl.STATIC_DRAW, gl.ELEMENT_ARRAY_BUFFER);
        return this.loaded = true;
      } else if (data.faces != null) {
        return this.parseThreeJSModel(data);
      }
    };

    JSONGeometry.prototype.parseThreeJSModel = function(data) {
      var faces, hasFaceColor, hasFaceNormal, hasFaceVertexColor, hasFaceVertexNormal, hasFaceVertexUv, hasMaterial, i, indices, isBitSet, isQuad, j, l, m, normal, normalIndex, normals, numUvLayers, o, offset, p, q, r, ref, ref1, type, u, uvIndex, uvLayer, uvs, v, vertexNormals, vertexPositions, vertexUvs, vertices, zLength;
      isBitSet = function(value, position) {
        return value & (1 << position);
      };
      vertices = data.vertices;
      uvs = data.uvs;
      indices = [];
      normals = data.normals;
      vertexNormals = [];
      vertexUvs = [];
      vertexPositions = [];
      this.vertexPositionBuffer = new DFIR.Buffer(new Float32Array(data.vertices), 3, gl.STATIC_DRAW);
      this.vertexTextureCoordBuffer = new DFIR.Buffer(new Float32Array(data.uvs[0]), 2, gl.STATIC_DRAW);
      numUvLayers = data.uvs.length;
      faces = data.faces;
      zLength = faces.length;
      offset = 0;
      while (offset < zLength) {
        type = faces[offset++];
        isQuad = isBitSet(type, 0);
        hasMaterial = isBitSet(type, 1);
        hasFaceVertexUv = isBitSet(type, 3);
        hasFaceNormal = isBitSet(type, 4);
        hasFaceVertexNormal = isBitSet(type, 5);
        hasFaceColor = isBitSet(type, 6);
        hasFaceVertexColor = isBitSet(type, 7);
        if (isQuad) {
          indices.push(faces[offset]);
          indices.push(faces[offset + 1]);
          indices.push(faces[offset + 3]);
          indices.push(faces[offset + 1]);
          indices.push(faces[offset + 2]);
          indices.push(faces[offset + 3]);
          offset += 4;
          if (hasMaterial) {
            offset++;
          }
          if (hasFaceVertexUv) {
            for (i = l = 0, ref = numUvLayers; l < ref; i = l += 1) {
              uvLayer = data.uvs[i];
              for (j = m = 0; m < 4; j = m += 1) {
                uvIndex = faces[offset++];
                u = uvLayer[uvIndex * 2];
                v = uvLayer[uvIndex * 2 + 1];
                if (j !== 2) {
                  vertexUvs.push(u);
                  vertexUvs.push(v);
                }
                if (j !== 0) {
                  vertexUvs.push(u);
                  vertexUvs.push(v);
                }
              }
            }
          }
          if (hasFaceNormal) {
            offset++;
          }
          if (hasFaceVertexNormal) {
            for (i = o = 0; o < 4; i = o += 1) {
              normalIndex = faces[offset++] * 3;
              normal = [normalIndex++, normalIndex++, normalIndex];
              if (i !== 2) {
                vertexNormals.push(normals[normal[0]]);
                vertexNormals.push(normals[normal[1]]);
                vertexNormals.push(normals[normal[2]]);
              }
              if (i !== 0) {
                vertexNormals.push(normals[normal[0]]);
                vertexNormals.push(normals[normal[1]]);
                vertexNormals.push(normals[normal[2]]);
              }
            }
          }
          if (hasFaceColor) {
            offset++;
          }
          if (hasFaceVertexColor) {
            offset += 4;
          }
        } else {
          indices.push(faces[offset++]);
          indices.push(faces[offset++]);
          indices.push(faces[offset++]);
          if (hasMaterial) {
            offset++;
          }
          if (hasFaceVertexUv) {
            for (i = p = 0, ref1 = numUvLayers; 0 <= ref1 ? p < ref1 : p > ref1; i = 0 <= ref1 ? ++p : --p) {
              uvLayer = data.uvs[i];
              for (j = q = 0; q < 3; j = ++q) {
                uvIndex = faces[offset++];
                u = uvLayer[uvIndex * 2];
                v = uvLayer[uvIndex * 2 + 1];
                if (j !== 2) {
                  vertexUvs.push(u);
                  vertexUvs.push(v);
                }
                if (j !== 0) {
                  vertexUvs.push(u);
                  vertexUvs.push(v);
                }
              }
            }
          }
          if (hasFaceNormal) {
            console.log("hasFaceNormal");
            offset++;
          }
          if (hasFaceVertexNormal) {
            for (i = r = 0; r < 3; i = r += 1) {
              normalIndex = faces[offset++];
              vertexNormals.push(normals[normalIndex++]);
              vertexNormals.push(normals[normalIndex++]);
              vertexNormals.push(normals[normalIndex]);
            }
          }
          if (hasFaceColor) {
            offset++;
          }
          if (hasFaceVertexColor) {
            offset += 3;
          }
        }
      }
      this.vertexNormalBuffer = new DFIR.Buffer(new Float32Array(vertexNormals), 3, gl.STATIC_DRAW);
      this.vertexIndexBuffer = new DFIR.Buffer(new Uint16Array(indices), 1, gl.STATIC_DRAW, gl.ELEMENT_ARRAY_BUFFER);
      return this.loaded = true;
    };

    JSONGeometry.prototype.normalizeNormals = function(normals) {
      var i, l, n, ref, x, y, z;
      for (i = l = 0, ref = normals.length; l < ref; i = l += 3) {
        x = normals[i];
        y = normals[i + 1];
        z = normals[i + 2];
        n = 1.0 / Math.sqrt(x * x + y * y + z * z);
        normals[i] *= n;
        normals[i + 1] *= n;
        normals[i + 2] *= n;
      }
      return normals;
    };

    JSONGeometry.load = function(url) {
      return new DFIR.JSONGeometry(url);
    };

    return JSONGeometry;

  })(DFIR.Object3D);

  getShader = function(id) {
    var k, shader, shaderScript, str;
    shaderScript = document.getElementById(id);
    if (!shaderScript) {
      return null;
    }
    str = "";
    k = shaderScript.firstChild;
    while (k) {
      if (k.nodeType === 3) {
        str += k.textContent;
      }
      k = k.nextSibling;
    }
    shader = null;
    if (shaderScript.type === "x-shader/x-fragment") {
      shader = gl.createShader(gl.FRAGMENT_SHADER);
    } else if (shaderScript.type === "x-shader/x-vertex") {
      shader = gl.createShader(gl.VERTEX_SHADER);
    } else {
      return null;
    }
    gl.shaderSource(shader, str);
    gl.compileShader(shader);
    console.log(id, gl.getShaderInfoLog(shader));
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      console.log(id, gl.getShaderInfoLog(shader));
      return null;
    }
    return shader;
  };

  DFIR.Uniform = (function() {
    function Uniform(name1, shaderProgram1) {
      this.name = name1;
      this.shaderProgram = shaderProgram1;
      this.location = gl.getUniformLocation(this.shaderProgram, this.name);
    }

    Uniform.prototype.setValue = function(value) {};

    return Uniform;

  })();

  DFIR.UniformMat4 = (function(superClass) {
    extend(UniformMat4, superClass);

    function UniformMat4() {
      return UniformMat4.__super__.constructor.apply(this, arguments);
    }

    UniformMat4.prototype.setValue = function(matrix) {
      return gl.uniformMatrix4fv(this.location, false, matrix);
    };

    return UniformMat4;

  })(DFIR.Uniform);

  DFIR.UniformFloat = (function(superClass) {
    extend(UniformFloat, superClass);

    function UniformFloat() {
      return UniformFloat.__super__.constructor.apply(this, arguments);
    }

    UniformFloat.prototype.setValue = function(value) {
      return gl.uniform1f(this.location, value);
    };

    return UniformFloat;

  })(DFIR.Uniform);

  DFIR.UniformMat3 = (function(superClass) {
    extend(UniformMat3, superClass);

    function UniformMat3() {
      return UniformMat3.__super__.constructor.apply(this, arguments);
    }

    UniformMat3.prototype.setValue = function(matrix) {
      return gl.uniformMatrix3fv(this.location, false, matrix);
    };

    return UniformMat3;

  })(DFIR.Uniform);

  DFIR.UniformVec3 = (function(superClass) {
    extend(UniformVec3, superClass);

    function UniformVec3() {
      return UniformVec3.__super__.constructor.apply(this, arguments);
    }

    UniformVec3.prototype.setValue = function(vec) {
      return gl.uniform3fv(this.location, 3, vec);
    };

    return UniformVec3;

  })(DFIR.Uniform);

  DFIR.ShaderSource = (function() {
    function ShaderSource(vertexSource1, fragmentSource1) {
      this.vertexSource = vertexSource1;
      this.fragmentSource = fragmentSource1;
    }

    return ShaderSource;

  })();

  DFIR.ShaderLoader = (function() {
    function ShaderLoader(vertUrl1, fragUrl1, callback1) {
      this.vertUrl = vertUrl1;
      this.fragUrl = fragUrl1;
      this.callback = callback1;
      this.onVertexLoaded = bind(this.onVertexLoaded, this);
      this.onFragmentLoaded = bind(this.onFragmentLoaded, this);
      this.fragmentLoaded = false;
      this.vertexLoaded = false;
      this.result = new DFIR.ShaderSource();
      loadShaderAjax(this.vertUrl, this.onVertexLoaded);
      loadShaderAjax(this.fragUrl, this.onFragmentLoaded);
    }

    ShaderLoader.prototype.checkLoaded = function() {
      var loaded;
      loaded = this.fragmentLoaded && this.vertexLoaded;
      return this.fragmentLoaded && this.vertexLoaded;
    };

    ShaderLoader.prototype.buildShader = function() {
      return buildShaderProgram(this.result.vertexSource, this.result.fragmentSource);
    };

    ShaderLoader.prototype.onFragmentLoaded = function(data) {
      var fragShader, fragmentLog;
      fragShader = gl.createShader(gl.FRAGMENT_SHADER);
      gl.shaderSource(fragShader, data);
      gl.compileShader(fragShader);
      if (fragmentLog = gl.getShaderInfoLog(fragShader)) {
        console.log(fragmentLog);
      }
      this.result.fragmentSource = fragShader;
      this.fragmentLoaded = true;
      if (this.checkLoaded()) {
        return this.callback(this.buildShader());
      }
    };

    ShaderLoader.prototype.onVertexLoaded = function(data) {
      var log, vertShader;
      vertShader = gl.createShader(gl.VERTEX_SHADER);
      gl.shaderSource(vertShader, data);
      gl.compileShader(vertShader);
      if (log = gl.getShaderInfoLog(vertShader)) {
        console.log(log);
      }
      this.result.vertexSource = vertShader;
      this.vertexLoaded = true;
      if (this.checkLoaded()) {
        return this.callback(this.buildShader());
      }
    };

    ShaderLoader.load = function(vertUrl, fragUrl, callback) {
      return new ShaderLoader(vertUrl, fragUrl, callback);
    };

    return ShaderLoader;

  })();

  loadResource = function(url, callback) {};

  loadShaderAjax = function(url, callback) {
    var request;
    request = new XMLHttpRequest();
    request.open('GET', url);
    request.onreadystatechange = function() {
      if (request.readyState === 4) {
        return callback(request.responseText);
      }
    };
    return request.send();
  };

  buildShaderProgram = function(vertexShader, fragmentShader) {
    var log, shaderProgram;
    shaderProgram = gl.createProgram();
    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragmentShader);
    gl.linkProgram(shaderProgram);
    if (log = gl.getProgramInfoLog(shaderProgram)) {
      console.log(log);
    }
    return shaderProgram;
  };

  buildProgram = function(vertexSourceId, fragmentSourceId) {
    var fragmentShader, vertexShader;
    fragmentShader = getShader(fragmentSourceId);
    vertexShader = getShader(vertexSourceId);
    return buildProgramFromStrings(vertexShader, fragmentShader);
  };

  buildProgramFromStrings = function(vertexSource, fragmentSource) {
    var shaderProgram;
    shaderProgram = gl.createProgram();
    gl.attachShader(shaderProgram, vertexSource);
    gl.attachShader(shaderProgram, fragmentSource);
    gl.linkProgram(shaderProgram);
    console.log(gl.getProgramInfoLog(shaderProgram));
    return shaderProgram;
  };

  shader_type_enums = {
    0x8B50: 'FLOAT_VEC2',
    0x8B51: 'FLOAT_VEC3',
    0x8B52: 'FLOAT_VEC4',
    0x8B53: 'INT_VEC2',
    0x8B54: 'INT_VEC3',
    0x8B55: 'INT_VEC4',
    0x8B56: 'BOOL',
    0x8B57: 'BOOL_VEC2',
    0x8B58: 'BOOL_VEC3',
    0x8B59: 'BOOL_VEC4',
    0x8B5A: 'FLOAT_MAT2',
    0x8B5B: 'FLOAT_MAT3',
    0x8B5C: 'FLOAT_MAT4',
    0x8B5E: 'SAMPLER_2D',
    0x8B60: 'SAMPLER_CUBE',
    0x1400: 'BYTE',
    0x1401: 'UNSIGNED_BYTE',
    0x1402: 'SHORT',
    0x1403: 'UNSIGNED_SHORT',
    0x1404: 'INT',
    0x1405: 'UNSIGNED_INT',
    0x1406: 'FLOAT'
  };

  getShaderParams = function(program) {
    var activeAttributes, activeUniforms, attribute, i, l, m, ref, ref1, result, uniform;
    gl.useProgram(program);
    result = {
      attributes: [],
      uniforms: [],
      attributeCount: 0,
      uniformCount: 0
    };
    activeUniforms = gl.getProgramParameter(program, gl.ACTIVE_UNIFORMS);
    activeAttributes = gl.getProgramParameter(program, gl.ACTIVE_ATTRIBUTES);
    for (i = l = 0, ref = activeUniforms; 0 <= ref ? l < ref : l > ref; i = 0 <= ref ? ++l : --l) {
      uniform = gl.getActiveUniform(program, i);
      uniform.typeName = shader_type_enums[uniform.type];
      result.uniforms.push(uniform);
      result.uniformCount += uniform.size;
    }
    for (i = m = 0, ref1 = activeAttributes; 0 <= ref1 ? m < ref1 : m > ref1; i = 0 <= ref1 ? ++m : --m) {
      attribute = gl.getActiveAttrib(program, i);
      attribute.typeName = shader_type_enums[attribute.type];
      result.attributes.push(attribute);
      result.attributeCount += attribute.size;
    }
    return result;
  };

  loadTexture = function(url, callback) {
    var tex;
    tex = gl.createTexture();
    tex.image = new Image();
    tex.image.onload = (function() {
      gl.bindTexture(gl.TEXTURE_2D, tex);
      gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, tex.image);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_NEAREST);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
      gl.generateMipmap(gl.TEXTURE_2D);
      gl.bindTexture(gl.TEXTURE_2D, null);
      return callback(tex);
    });
    return tex.image.src = url;
  };

  DFIR.TextureMapTypes = (function() {
    function TextureMapTypes() {}

    TextureMapTypes.DIFFUSE = 0x01;

    TextureMapTypes.NORMAL = 0x02;

    TextureMapTypes.SPECULAR = 0x03;

    TextureMapTypes.CUBE = 0x04;

    TextureMapTypes.SPHERE = 0x05;

    return TextureMapTypes;

  })();

  DFIR.Color = (function() {
    function Color(r, g, b1, a1) {
      this.r = r != null ? r : 1.0;
      this.g = g != null ? g : 1.0;
      this.b = b1 != null ? b1 : 1.0;
      this.a = a1 != null ? a1 : 1.0;
    }

    Color.prototype.getRGB = function() {
      return vec3.fromValues(this.r, this.g, this.b);
    };

    Color.prototype.getRGBA = function() {
      return vec4.fromValues(this.r, this.g, this.b, this.a);
    };

    return Color;

  })();

  DFIR.Shader = (function() {
    function Shader(program1) {
      this.program = program1;
      this.params = getShaderParams(this.program);
      this.diffuseMapLoaded = this.normalMapLoaded = false;
      this.buildUniforms();
      this.buildAttributes();
    }

    Shader.prototype.buildUniforms = function() {
      var l, len, ref, results, u;
      this.uniforms = {};
      ref = this.params.uniforms;
      results = [];
      for (l = 0, len = ref.length; l < len; l++) {
        u = ref[l];
        results.push(this.uniforms[u.name] = gl.getUniformLocation(this.program, u.name));
      }
      return results;
    };

    Shader.prototype.buildAttributes = function() {
      var a, l, len, ref, results;
      this.attributes = {};
      ref = this.params.attributes;
      results = [];
      for (l = 0, len = ref.length; l < len; l++) {
        a = ref[l];
        results.push(this.attributes[a.name] = gl.getAttribLocation(this.program, a.name));
      }
      return results;
    };

    Shader.prototype.use = function() {
      return gl.useProgram(this.program);
    };

    Shader.prototype.showInfo = function() {
      console.log(this.program);
      console.table(this.params.uniforms);
      return console.table(this.params.attributes);
    };

    Shader.prototype.setDiffuseMap = function(url) {
      return loadTexture(url, (function(_this) {
        return function(texture) {
          _this.diffuseMap = texture;
          return _this.diffuseMapLoaded = true;
        };
      })(this));
    };

    Shader.prototype.setNormalMap = function(url) {
      return loadTexture(url, (function(_this) {
        return function(texture) {
          _this.normalMap = texture;
          return _this.normalMapLoaded = true;
        };
      })(this));
    };

    Shader.prototype.getUniform = function(name) {
      return this.uniforms[name];
    };

    Shader.prototype.getAttribute = function(name) {
      return this.attributes[name];
    };

    return Shader;

  })();

  DFIR.PBRShader = (function(superClass) {
    extend(PBRShader, superClass);

    function PBRShader(program1) {
      this.program = program1;
      PBRShader.__super__.constructor.call(this, this.program);
      this.metallic = 0.0;
      this.roughness = 0.0;
      this.diffuseColor = new DFIR.Color(0.2, 1.0, 1.0);
    }

    PBRShader.prototype.use = function() {
      gl.useProgram(this.program);
      gl.uniform1f(this.getUniform('metallic'), this.metallic);
      gl.uniform1f(this.getUniform('roughness'), this.roughness);
      return gl.uniform3fv(this.getUniform('diffuseColor'), this.diffuseColor.getRGB());
    };

    return PBRShader;

  })(DFIR.Shader);

  loadJSON = function(url, callback) {
    var key, request;
    key = md5(url);
    if (DFIR.Geometry.meshCache[key] != null) {
      console.log('Not loading #{url}');
      callback(DFIR.Geometry.meshCache[key]);
      return;
    }
    request = new XMLHttpRequest();
    request.open('GET', url);
    request.onreadystatechange = function() {
      var result;
      if (request.readyState === 4) {
        result = JSON.parse(request.responseText);
        DFIR.Geometry.meshCache[key] = result;
        return callback(JSON.parse(request.responseText));
      }
    };
    return request.send();
  };

  DFIR.Resource = (function() {
    function Resource(url1) {
      this.url = url1 != null ? url1 : null;
      this.id = DFIR.nextId();
    }

    Resource.prototype.load = function() {};

    Resource.prototype.unload = function() {};

    Resource.prototype.bind = function() {};

    return Resource;

  })();

  DFIR.ModelResource = (function(superClass) {
    extend(ModelResource, superClass);

    function ModelResource(url1) {
      this.url = url1;
      this.onDataLoaded = bind(this.onDataLoaded, this);
      ModelResource.__super__.constructor.call(this);
      loadJSON(this.url, this.onDataLoaded);
    }

    ModelResource.prototype.setMaterial = function(shader) {
      return this.material = shader;
    };

    ModelResource.prototype.onDataLoaded = function(data) {
      this.vertexPositionBuffer = new DFIR.Buffer(new Float32Array(data.vertexPositions), 3, gl.STATIC_DRAW);
      this.vertexTextureCoordBuffer = new DFIR.Buffer(new Float32Array(data.vertexTextureCoords), 2, gl.STATIC_DRAW);
      this.vertexNormalBuffer = new DFIR.Buffer(new Float32Array(data.vertexNormals), 3, gl.STATIC_DRAW);
      this.vertexIndexBuffer = new DFIR.Buffer(new Uint16Array(data.indices), 1, gl.STATIC_DRAW, gl.ELEMENT_ARRAY_BUFFER);
      return this.loaded = true;
    };

    ModelResource.prototype.ready = function() {
      return this.ready || (this.ready = (this.loaded && this.material && this.material.ready) != null);
    };

    ModelResource.prototype.bind = function() {
      var normalsAttrib, positionAttrib, texCoordsAttrib;
      if (!this.ready()) {
        return false;
      }
      this.material.use();
      positionAttrib = this.material.getAttribute('aVertexPosition');
      texCoordsAttrib = this.material.getAttribute('aVertexTextureCoords');
      normalsAttrib = this.material.getAttribute('aVertexNormal');
      gl.enableVertexAttribArray(positionAttrib);
      gl.bindBuffer(gl.ARRAY_BUFFER, this.vertexPositionBuffer.get());
      gl.vertexAttribPointer(positionAttrib, this.vertexPositionBuffer.itemSize, gl.FLOAT, false, 12, 0);
      gl.enableVertexAttribArray(texCoordsAttrib);
      gl.bindBuffer(gl.ARRAY_BUFFER, this.vertexTextureCoordBuffer.get());
      gl.vertexAttribPointer(texCoordsAttrib, this.vertexTextureCoordBuffer.itemSize, gl.FLOAT, false, 8, 0);
      gl.enableVertexAttribArray(normalsAttrib);
      gl.bindBuffer(gl.ARRAY_BUFFER, this.vertexNormalBuffer.get());
      gl.vertexAttribPointer(normalsAttrib, this.vertexNormalBuffer.itemSize, gl.FLOAT, false, 12, 0);
      return true;
      return {
        release: function() {
          return gl.bindBuffer(gl.ARRAY_BUFFER, null);
        }
      };
    };

    return ModelResource;

  })(DFIR.Resource);

  InertialValue = (function() {
    function InertialValue(value1, damping, dt1) {
      this.value = value1;
      this.dt = dt1;
      this.damping = Math.pow(damping, this.dt);
      this.last = this.value;
      this.display = this.value;
      this.velocity = 0;
    }

    InertialValue.prototype.accelerate = function(acceleration) {
      return this.velocity += acceleration * this.dt;
    };

    InertialValue.prototype.integrate = function() {
      this.velocity *= this.damping;
      this.last = this.value;
      return this.value += this.velocity * this.dt;
    };

    InertialValue.prototype.interpolate = function(f) {
      return this.display = this.last * f + (1 - f) * this.value;
    };

    InertialValue.prototype.get = function() {
      return this.display;
    };

    InertialValue.prototype.set = function(value1) {
      this.value = value1;
      return this.last = this.value;
    };

    return InertialValue;

  })();

  InertialVector = (function() {
    function InertialVector(x, y, z, damping, dt) {
      this.x = new InertialValue(x, damping, dt);
      this.y = new InertialValue(y, damping, dt);
      this.z = new InertialValue(z, damping, dt);
    }

    InertialVector.prototype.accelerate = function(x, y, z) {
      this.x.accelerate(x);
      this.y.accelerate(y);
      return this.z.accelerate(z);
    };

    InertialVector.prototype.integrate = function() {
      this.x.integrate();
      this.y.integrate();
      return this.z.integrate();
    };

    InertialVector.prototype.interpolate = function(f) {
      this.x.interpolate(f);
      this.y.interpolate(f);
      return this.z.interpolate(f);
    };

    InertialVector.prototype.set = function(x, y, z) {
      if (x instanceof Array) {
        this.x.set(x[0]);
        this.y.set(x[1]);
        return this.z.set(x[2]);
      } else {
        this.x.set(x);
        this.y.set(y);
        return this.z.set(z);
      }
    };

    return InertialVector;

  })();

  DFIR.Camera = (function(superClass) {
    extend(Camera, superClass);

    function Camera(viewportWidth, viewportHeight) {
      this.viewportWidth = viewportWidth;
      this.viewportHeight = viewportHeight;
      if (this.viewportWidth == null) {
        this.viewportWidth = gl.viewportWidth;
      }
      if (this.viewportHeight == null) {
        this.viewportHeight = gl.viewportHeight;
      }
      this.target = vec3.create();
      this.fov = 45.0;
      this.up = vec3.fromValues(0.0, 1.0, 0.0);
      this.viewMatrix = mat4.create();
      this.viewProjectionMatrix = mat4.create();
      this.near = 0.01;
      this.far = 60.0;
      this.projectionMatrix = mat4.create();
    }

    Camera.prototype.setFarClip = function(far) {
      this.far = far;
      return this.updateProjectionMatrix();
    };

    Camera.prototype.setNearClip = function(near) {
      this.near = near;
      return this.updateProjectionMatrix();
    };

    Camera.prototype.getViewMatrix = function() {
      return this.viewMatrix;
    };

    Camera.prototype.getProjectionMatrix = function() {
      return this.projectionMatrix;
    };

    Camera.prototype.getViewProjectionMatrix = function() {
      return this.viewProjectionMatrix;
    };

    Camera.prototype.getFrustumCorners = function() {
      var Cfar, Cnear, Hfar, Hnear, Wfar, Wnear, ar, fov, v, w;
      v = vec3.create();
      vec3.sub(v, this.target, this.position);
      vec3.normalize(v, v);
      w = vec3.create();
      vec3.cross(w, viewVector, this.up);
      fov = this.fov * Math.PI / 180.0;
      ar = this.viewportWidth / this.viewportHeight;
      Hnear = 2 * Math.tan(fov / 2.0) * this.near;
      Wnear = Hnear * ar;
      Hfar = 2 * Math.tan(fov / 2.0) * this.far;
      Wfar = Hfar * ar;
      Cnear = vec3.create();
      Cfar = vec3.create();
      vec3.add(Cnear, this.position, v);
      vec3.scale(Cnear, Cnear, this.near);
      vec3.add(Cfar, this.position, v);
      return vec3.scale(Cfar, Cfar, this.far);
    };

    Camera.prototype.getInverseProjectionMatrix = function() {
      var invProjMatrix;
      invProjMatrix = mat4.create();
      mat4.invert(invProjMatrix, this.projectionMatrix);
      return invProjMatrix;
    };

    Camera.prototype.getInverseViewProjectionMatrix = function() {
      var vpMatrix;
      vpMatrix = mat4.create();
      mat4.invert(vpMatrix, this.viewProjectionMatrix);
      return vpMatrix;
    };

    Camera.prototype.updateViewMatrix = function() {
      mat4.identity(this.viewMatrix);
      return mat4.lookAt(this.viewMatrix, this.position, this.target, this.up);
    };

    Camera.prototype.updateProjectionMatrix = function() {
      var aspect;
      mat4.identity(this.projectionMatrix);
      aspect = this.viewportWidth / this.viewportHeight;
      mat4.perspective(this.projectionMatrix, this.fov, aspect, this.near, this.far);
      return mat4.multiply(this.viewProjectionMatrix, this.projectionMatrix, this.viewMatrix);
    };

    return Camera;

  })(DFIR.Object3D);

  Pointer = (function() {
    function Pointer(element, onMove) {
      this.element = element;
      this.mouseMove = bind(this.mouseMove, this);
      this.mouseUp = bind(this.mouseUp, this);
      this.mouseDown = bind(this.mouseDown, this);
      this.onMove = onMove != null ? onMove : function() {
        return null;
      };
      this.pressed = false;
      this.x = null;
      this.y = null;
      this.element.addEventListener('mousedown', this.mouseDown);
      this.element.addEventListener('mouseup', this.mouseUp);
      this.element.addEventListener('mousemove', this.mouseMove);
    }

    Pointer.prototype.mouseDown = function(event) {
      return this.pressed = true;
    };

    Pointer.prototype.mouseUp = function(event) {
      return this.pressed = false;
    };

    Pointer.prototype.mouseMove = function(event) {
      var dx, dy, rect, x, y;
      rect = this.element.getBoundingClientRect();
      x = event.clientX - rect.left;
      y = event.clientY - rect.top;
      if (this.x != null) {
        dx = this.x - x;
        dy = this.y - y;
      } else {
        dx = 0;
        dy = 0;
      }
      this.x = x;
      this.y = y;
      return this.onMove(this.x, this.y, dx, dy);
    };

    return Pointer;

  })();

  keymap = {
    87: 'w',
    65: 'a',
    83: 's',
    68: 'd',
    81: 'q',
    69: 'e',
    37: 'left',
    39: 'right',
    38: 'up',
    40: 'down',
    13: 'enter',
    27: 'esc',
    32: 'space',
    8: 'backspace',
    16: 'shift',
    17: 'ctrl',
    18: 'alt',
    91: 'start',
    0: 'altc',
    20: 'caps',
    9: 'tab',
    49: 'key1',
    50: 'key2',
    51: 'key3',
    52: 'key4'
  };

  keys = {};

  for (value in keymap) {
    name = keymap[value];
    keys[name] = false;
  }

  document.addEventListener('keydown', function(event) {
    name = keymap[event.keyCode];
    return keys[name] = true;
  });

  document.addEventListener('keyup', function(event) {
    name = keymap[event.keyCode];
    return keys[name] = false;
  });

  DFIR.FPSCamera = (function(superClass) {
    extend(FPSCamera, superClass);

    function FPSCamera(viewportWidth, viewportHeight, canvas1) {
      this.viewportWidth = viewportWidth;
      this.viewportHeight = viewportHeight;
      this.canvas = canvas1;
      this.pointerMove = bind(this.pointerMove, this);
      FPSCamera.__super__.constructor.call(this);
      this.origin = vec3.create();
      this.rotation = 0;
      this.pitch = 0;
      this.rotVec = vec3.create();
      this.pointer = new Pointer(this.canvas, this.pointerMove);
      this.dt = 1 / 24;
      this.position = new InertialVector(0, 0, 0, 0.05, this.dt);
      this.time = performance.now() / 1000;
      console.log(this.position);
    }

    FPSCamera.prototype.setPosition = function(vec) {
      return this.position.set(vec[0], vec[1], vec[2]);
    };

    FPSCamera.prototype.pointerMove = function(x, y, dx, dy) {
      if (this.pointer.pressed) {
        this.rotation -= dx * 0.01;
        return this.pitch -= dy * 0.01;
      }
    };

    FPSCamera.prototype.step = function() {
      var f, now;
      now = performance.now() / 1000;
      while (this.time < now) {
        this.time += this.dt;
        this.position.integrate();
      }
      f = (this.time - now) / this.dt;
      return this.position.interpolate(f);
    };

    FPSCamera.prototype.cameraAcceleration = function() {};

    FPSCamera.prototype.update = function() {
      this.cameraAcceleration();
      return this.step();
    };

    FPSCamera.prototype.updateViewMatrix = function() {
      var pos;
      mat4.identity(this.viewMatrix);
      mat4.rotateX(this.viewMatrix, this.viewMatrix, this.pitch);
      mat4.rotateY(this.viewMatrix, this.viewMatrix, this.rotation);
      if (this.position.x) {
        pos = vec3.fromValues(this.position.x.display, this.position.y.display, this.position.z.display);
        return mat4.translate(this.viewMatrix, this.viewMatrix, pos);
      }
    };

    return FPSCamera;

  })(DFIR.Camera);

  DFIR.QuaternionCamera = (function(superClass) {
    extend(QuaternionCamera, superClass);

    function QuaternionCamera(viewportWidth, viewportHeight, canvas1) {
      this.viewportWidth = viewportWidth;
      this.viewportHeight = viewportHeight;
      this.canvas = canvas1;
      this.rotateCamera = bind(this.rotateCamera, this);
      this.pointerMove = bind(this.pointerMove, this);
      QuaternionCamera.__super__.constructor.call(this, this.viewportWidth, this.viewportHeight);
      this.sensitivity = 200.0;
      this.pointer = new Pointer(this.canvas, this.pointerMove);
      this.rotx = 0.0;
      this.up = vec3.fromValues(0.0, 1.0, 0.0);
      this.view = vec3.fromValues(0.0, 0.0, 1.0);
      this.dt = 1 / 24;
      this.position = new InertialVector(0, 0, 0, 0.05, this.dt);
      this.time = performance.now() / 1000;
    }

    QuaternionCamera.prototype.pointerMove = function(x, y, dx, dy) {
      var axis, mx, my, pos, rotx, vp;
      if (this.pointer.pressed) {
        rotx = 0.0;
        mx = dx / this.sensitivity;
        my = dy / this.sensitivity;
        this.rotx += my;
        pos = vec3.fromValues(this.position.x.display, this.position.y.display, this.position.z.display);
        axis = vec3.create();
        vp = vec3.create();
        vec3.subtract(vp, this.view, pos);
        vec3.cross(axis, vp, this.up);
        vec3.normalize(axis, axis);
        this.rotateCamera(my, axis[0], axis[1], axis[2]);
        return this.rotateCamera(mx, 0.0, 1.0, 0.0);
      }
    };

    QuaternionCamera.prototype.rotateCamera = function(angle, x, y, z) {
      var quat_view, result, tc, temp, tv;
      quat_view = quat.create();
      result = quat.create();
      tv = quat.create();
      tc = quat.create();
      temp = quat.fromValues(x * Math.sin(angle / 2), y * Math.sin(angle / 2), z * Math.sin(angle / 2), Math.cos(angle / 2));
      quat_view = quat.fromValues(this.view[0], this.view[1], this.view[2], 0.0);
      quat.multiply(tv, temp, quat_view);
      quat.conjugate(temp, temp);
      quat.multiply(result, tv, temp);
      return vec3.set(this.view, result[0], result[1], result[2]);
    };

    QuaternionCamera.prototype.updateViewMatrix = function() {
      var look, target;
      target = vec3.fromValues(this.position.x.display, this.position.y.display, this.position.z.display);
      look = vec3.clone(this.view);
      vec3.add(target, target, look);
      return mat4.lookAt(this.viewMatrix, [this.position.x.display, this.position.y.display, this.position.z.display], target, this.up);
    };

    QuaternionCamera.prototype.getViewMatrix = function() {
      return this.viewMatrix;
    };

    QuaternionCamera.prototype.getViewRotationMatrix = function() {
      var vrMatrix;
      vrMatrix = mat4.create();
      mat4.lookAt(vrMatrix, [0.0, 0.0, 0.0], this.view, this.up);
      return vrMatrix;
    };

    QuaternionCamera.prototype.setPosition = function(vec) {
      return this.position.set(vec[0], vec[1], vec[2]);
    };

    QuaternionCamera.prototype.step = function() {
      var f, now;
      now = performance.now() / 1000;
      while (this.time < now) {
        this.time += this.dt;
        this.position.integrate();
      }
      f = (this.time - now) / this.dt;
      return this.position.interpolate(f);
    };

    QuaternionCamera.prototype.cameraAcceleration = function() {
      var acc, vel;
      acc = 300.0;
      vel = vec3.clone(this.view);
      vec3.scale(vel, vel, acc);
      if (keys.s) {
        this.position.accelerate(-vel[0], -vel[1], -vel[2]);
      }
      if (keys.w) {
        this.position.accelerate(vel[0], vel[1], vel[2]);
      }
      vec3.cross(vel, this.view, this.up);
      vec3.scale(vel, vel, acc);
      if (keys.a) {
        this.position.accelerate(-vel[0], -vel[1], -vel[2]);
      }
      if (keys.d) {
        return this.position.accelerate(vel[0], vel[1], vel[2]);
      }
    };

    QuaternionCamera.prototype.update = function() {
      this.cameraAcceleration();
      return this.step();
    };

    return QuaternionCamera;

  })(DFIR.Camera);

  DFIR.Light = (function() {
    function Light(position1, color, strength, attenuation) {
      this.position = position1;
      this.color = color;
      this.strength = strength != null ? strength : 1.0;
      this.attenuation = attenuation != null ? attenuation : 1.0;
      if (this.color == null) {
        this.color = vec3.fromValues(1.0, 1.0, 1.0);
      }
    }

    return Light;

  })();

  DFIR.DirectionalLight = (function(superClass) {
    extend(DirectionalLight, superClass);

    function DirectionalLight() {
      return DirectionalLight.__super__.constructor.apply(this, arguments);
    }

    return DirectionalLight;

  })(DFIR.Light);

  DFIR.ShadowCamera = (function(superClass) {
    extend(ShadowCamera, superClass);

    function ShadowCamera() {
      return ShadowCamera.__super__.constructor.apply(this, arguments);
    }

    return ShadowCamera;

  })(DFIR.Camera);

  DFIR.Gbuffer = (function() {
    function Gbuffer(resolution) {
      this.resolution = resolution != null ? resolution : 1.0;
      this.width = gl.viewportWidth / this.resolution;
      this.height = gl.viewportHeight / this.resolution;
      this.createFrameBuffer();
    }

    Gbuffer.prototype.createFrameBuffer = function() {
      var status;
      this.mrt_ext = gl.getExtension('WEBGL_draw_buffers');
      this.half_ext = gl.getExtension("OES_texture_half_float");
      this.depth_ext = gl.getExtension("WEBKIT_WEBGL_depth_texture") || gl.getExtension("WEBGL_depth_texture");
      this.frameBuffer = gl.createFramebuffer();
      gl.bindFramebuffer(gl.FRAMEBUFFER, this.frameBuffer);
      this.albedoTextureUnit = this.createTexture();
      this.normalsTextureUnit = this.createTexture(this.half_ext.HALF_FLOAT_OES);
      this.depthComponent = this.createDepthTexture();
      gl.framebufferTexture2D(gl.FRAMEBUFFER, this.mrt_ext.COLOR_ATTACHMENT0_WEBGL, gl.TEXTURE_2D, this.albedoTextureUnit, 0);
      gl.framebufferTexture2D(gl.FRAMEBUFFER, this.mrt_ext.COLOR_ATTACHMENT1_WEBGL, gl.TEXTURE_2D, this.normalsTextureUnit, 0);
      gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.TEXTURE_2D, this.depthComponent, 0);
      status = gl.checkFramebufferStatus(gl.FRAMEBUFFER);
      console.log("GBuffer FrameBuffer status after initialization: " + status);
      return this.release();
    };

    Gbuffer.prototype.createDepthTexture = function() {
      var tex;
      tex = gl.createTexture();
      gl.bindTexture(gl.TEXTURE_2D, tex);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.DEPTH_COMPONENT, this.width, this.height, 0, gl.DEPTH_COMPONENT, gl.UNSIGNED_SHORT, null);
      return tex;
    };

    Gbuffer.prototype.createTexture = function(format) {
      var tex;
      if (format == null) {
        format = this.half_ext.HALF_FLOAT_OES;
      }
      tex = gl.createTexture();
      gl.bindTexture(gl.TEXTURE_2D, tex);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, this.width, this.height, 0, gl.RGBA, format, null);
      return tex;
    };

    Gbuffer.prototype.bind = function() {
      gl.bindFramebuffer(gl.FRAMEBUFFER, this.frameBuffer);
      return this.mrt_ext.drawBuffersWEBGL([this.mrt_ext.COLOR_ATTACHMENT0_WEBGL, this.mrt_ext.COLOR_ATTACHMENT1_WEBGL]);
    };

    Gbuffer.prototype.release = function() {
      this.mrt_ext.drawBuffersWEBGL([gl.NONE]);
      return gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    };

    Gbuffer.prototype.getDepthTextureUnit = function() {
      return this.depthComponent;
    };

    Gbuffer.prototype.getAlbedoTextureUnit = function() {
      return this.albedoTextureUnit;
    };

    Gbuffer.prototype.getNormalsTextureUnit = function() {
      return this.normalsTextureUnit;
    };

    return Gbuffer;

  })();

  fs_quad_vertex_shader = "attribute vec3 aVertexPosition;\nattribute vec2 aVertexTextureCoords;\n\nvarying vec2 vTexCoords;\n\nvoid main( void ) {\n  // passthru\n  gl_Position = vec4(aVertexPosition, 1.0);\n  \n  vTexCoords = aVertexTextureCoords;\n}\n";

  fs_quad_fragment_shader = "varying vec2 vTexCoords;\n\nvoid main (void) {\n  gl_FragColor = vec4(vTexCoords, 1.0, 1.0);\n}\n";

  DFIR.DebugGridView = (function() {
    function DebugGridView(num_levels) {
      this.build_geometry(num_levels);
    }

    DebugGridView.prototype.build_geometry = function(num_levels) {
      var current_level, f, ht, indices, l, ref, texcoords, verts, wd, x, y;
      x = -1.0;
      y = -1.0;
      ht = 2.0 / num_levels;
      wd = 0.5;
      this.vertices = [];
      this.textureCoords = [];
      this.indices = [];
      f = 0;
      for (current_level = l = 1, ref = num_levels; 1 <= ref ? l <= ref : l >= ref; current_level = 1 <= ref ? ++l : --l) {
        verts = [x, y, current_level, x + ht, y, current_level, x + ht, y + ht, current_level, x, y + ht, current_level];
        texcoords = [0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0];
        indices = [f, f + 1, f + 2, f + 2, f + 3, f];
        f += 4;
        x = x + ht;
        this.vertices = this.vertices.concat(verts);
        this.textureCoords = this.textureCoords.concat(texcoords);
        this.indices = this.indices.concat(indices);
      }
      this.vertexBuffer = new DFIR.Buffer(new Float32Array(this.vertices), 3, gl.STATIC_DRAW);
      this.textureBuffer = new DFIR.Buffer(new Float32Array(this.textureCoords), 2, gl.STATIC_DRAW);
      return this.indexBuffer = new DFIR.Buffer(new Uint16Array(this.indices), 1, gl.STATIC_DRAW, gl.ELEMENT_ARRAY_BUFFER);
    };

    DebugGridView.prototype.bind = function(material) {
      gl.bindBuffer(gl.ARRAY_BUFFER, this.vertexBuffer.get());
      gl.enableVertexAttribArray(material.getAttribute('aVertexPosition'));
      gl.vertexAttribPointer(material.getAttribute('aVertexPosition'), 3, gl.FLOAT, false, 0, 0);
      gl.bindBuffer(gl.ARRAY_BUFFER, this.textureBuffer.get());
      gl.enableVertexAttribArray(material.getAttribute('aVertexTextureCoords'));
      return gl.vertexAttribPointer(material.getAttribute('aVertexTextureCoords'), 2, gl.FLOAT, false, 0, 0);
    };

    DebugGridView.prototype.draw = function() {
      gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.indexBuffer.get());
      return gl.drawElements(gl.TRIANGLES, this.indexBuffer.numItems, gl.UNSIGNED_SHORT, 0);
    };

    DebugGridView.prototype.release = function() {
      return gl.bindBuffer(gl.ARRAY_BUFFER, null);
    };

    return DebugGridView;

  })();

  DFIR.FullscreenQuad = (function(superClass) {
    extend(FullscreenQuad, superClass);

    function FullscreenQuad() {
      FullscreenQuad.__super__.constructor.call(this);
      this.vertices = [-1.0, -1.0, 1.0, -1.0, -1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0, 1.0];
      this.textureCoords = [0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0];
      this.vertexBuffer = new DFIR.Buffer(new Float32Array(this.vertices), 2, gl.STATIC_DRAW);
      this.textureBuffer = new DFIR.Buffer(new Float32Array(this.textureCoords), 2, gl.STATIC_DRAW);
    }

    FullscreenQuad.prototype.setMaterial = function(shader) {
      return this.material = shader;
    };

    FullscreenQuad.prototype.bind = function() {
      gl.bindBuffer(gl.ARRAY_BUFFER, this.vertexBuffer.get());
      gl.enableVertexAttribArray(this.material.getAttribute('aVertexPosition'));
      gl.vertexAttribPointer(this.material.getAttribute('aVertexPosition'), 2, gl.FLOAT, false, 0, 0);
      gl.bindBuffer(gl.ARRAY_BUFFER, this.textureBuffer.get());
      gl.enableVertexAttribArray(this.material.getAttribute('aVertexTextureCoords'));
      return gl.vertexAttribPointer(this.material.getAttribute('aVertexTextureCoords'), 2, gl.FLOAT, false, 0, 0);
    };

    FullscreenQuad.prototype.release = function() {
      return gl.bindBuffer(gl.ARRAY_BUFFER, null);
    };

    return FullscreenQuad;

  })(DFIR.Object3D);

  initTexture = function(width, height, format, attachment) {};

  DFIR.FrameBuffer = (function() {
    function FrameBuffer(width1, height1, colorTargets, depthTarget) {
      this.width = width1;
      this.height = height1;
      this.colorTargets = colorTargets != null ? colorTargets : 1;
      this.depthTarget = depthTarget != null ? depthTarget : true;
      this.textures = [];
      this.init();
    }

    FrameBuffer.prototype.check = function() {
      this.ext = window.WEBGL_draw_buffers = gl.getExtension('WEBGL_draw_buffers');
      if (this.ext == null) {
        return alert('Draw Buffers unsupported');
      }
    };

    FrameBuffer.prototype.init = function() {
      var i, l, ref, results;
      this.fb = gl.createFramebuffer();
      gl.bindFramebuffer(gl.FRAMEBUFFER, this.fb);
      results = [];
      for (i = l = 0, ref = this.colorTargets; 0 <= ref ? l < ref : l > ref; i = 0 <= ref ? ++l : --l) {
        results.push(this.textures[i] = initTexture(this.width, this.height, gl.RGB4, gl.COLOR_ATTACHMENT0 + i));
      }
      return results;
    };

    FrameBuffer.prototype.bind = function() {};

    return FrameBuffer;

  })();

  tCache = null;

  debug_textures = [];

  shader = null;

  triangle = function() {
    var buf, vao, verts;
    vao = tCache;
    if (vao == null) {
      verts = new Float32Array([-1, -1, -1, 4, 4, -1]);
      buf = new DFIR.Buffer(verts, 2, gl.STATIC_DRAW);
      tCache = vao = buf;
      vao = buf;
    }
    vao.bind();
    gl.drawArrays(gl.TRIANGLES, 0, 3);
    return vao.release();
  };

  texturedebug = function(textures) {
    var height, i, l, localHeight, localWidth, padding, ref, results, startX, startY, width, x, y;
    width = gl.drawingBufferWidth;
    height = gl.drawingBufferHeight;
    if (shader == null) {
      DFIR.ShaderLoader.load('shaders/triangle_vert.glsl', 'shaders/triangle_frag.glsl', function(program) {
        return shader = new DFIR.Shader(program);
      });
    }
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.disable(gl.DEPTH_TEST);
    gl.disable(gl.CULL_FACE);
    gl.disable(gl.BLEND);
    padding = 10;
    localWidth = width * 0.15;
    localHeight = localWidth * (height / width);
    startX = width - localWidth - padding;
    startY = height - localHeight - padding;
    if (shader != null) {
      shader.use();
      gl.uniform2fv(shader.getUniform('res'), [localWidth, localHeight]);
      results = [];
      for (i = l = 0, ref = textures.length; 0 <= ref ? l < ref : l > ref; i = 0 <= ref ? ++l : --l) {
        x = startX;
        y = startY - localHeight * i - padding * i;
        gl.viewport(x, y, localWidth, localHeight);
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, textures[i]);
        gl.uniform1i(shader.getUniform('tex'), 0);
        results.push(triangle());
      }
      return results;
    }
  };

  exports = typeof exports !== 'undefined' ? exports : window;

  exports.texturedebug = texturedebug;

  DebugView = (function() {
    function DebugView(gbuffer, num_views) {
      this.gbuffer = gbuffer;
      if (num_views == null) {
        num_views = 6;
      }
      this.depthTex = this.gbuffer.getDepthTextureUnit();
      this.normalsTex = this.guffer.getNormalsTexture();
      this.albedoTex = this.gbuffer.getAlbedoTextureUnit();
      this.createMaterial();
      this.createQuads(num_views);
    }

    DebugView.prototype.draw = function(camera) {
      var i, l, ref, results;
      this.material.use();
      gl.activeTexture(gl.TEXTURE0);
      gl.bindTexture(gl.TEXTURE_2D, this.gbuffer.getDepthTextureUnit());
      gl.activeTexture(gl.TEXTURE1);
      gl.bindTexture(gl.TEXTURE_2D, this.gbuffer.getNormalsTextureUnit());
      gl.activeTexture(gl.TEXTURE2);
      gl.bindTexture(gl.TEXTURE_2D, this.gbuffer.getAlbedoTextureUnit());
      gl.uniform1i(this.material.getUniform('depthTexture'), 0);
      gl.uniform1i(this.material.getUniform('normalsTexture'), 1);
      gl.uniform1i(this.material.getUniform('albedoTexture'), 2);
      gl.uniformMatrix4fv(this.material.getUniform('inverseProjectionMatrix'), false, camera.getInverseProjectionMatrix());
      results = [];
      for (i = l = 0, ref = this.quads.length; 0 <= ref ? l <= ref : l >= ref; i = 0 <= ref ? ++l : --l) {
        results.push(this.drawQuad(i));
      }
      return results;
    };

    DebugView.prototype.drawQuad = function(index) {
      this.quads[i].bind();
      gl.uniform1i(this.material.getUniform('DEBUG'), index);
      gl.drawArrays(gl.TRIANGLES, 0, this.quads[i].vertexBuffer.numItems);
      return this.quads[i].release();
    };

    DebugView.prototype.createMaterial = function() {
      this.material = new DFIR.Shader("fs_quad_vert", "fs_quad_frag");
      return this.debug_uniform_location = this.material.getUniform('DEBUG');
    };

    DebugView.prototype.createQuads = function(num) {
      var tileHeight, tileWidth, tiles, x, y;
      tiles = Math.ceil(Math.sqrt(num));
      tileWidth = gl.viewportWidth / tiles;
      tileHeight = gl.viewportHeight / tiles;
      x = 0;
      y = 0;
      return this.quads = [];
    };

    DebugView.prototype.createQuad = function(x, y, w, h) {};

    return DebugView;

  })();

  DFIR.Transform = (function() {
    function Transform() {
      this._translation = vec3.create();
      this._scale = vec3.fromValues(1.0, 1.0, 1.0);
      this._rotation = quat.create();
    }

    Transform.prototype.translate = function(vec) {
      return vec3.add(this._translation, this._translation, vec);
    };

    Transform.prototype.scale = function(num) {
      return vec3.scale(this._scale, this._scale, num);
    };

    Transform.prototype.scaleVector = function(vec) {
      return vec3.multiply(this._scale, this._scale, vec);
    };

    Transform.prototype.rotateX = function(rad) {
      return quat.rotateX(this._rotation, this._rotation, rad);
    };

    Transform.prototype.rotateY = function(rad) {
      return quat.rotateY(this._rotation, this._rotation, rad);
    };

    Transform.prototype.rotateZ = function(rad) {
      return quat.rotateZ(this._rotation, this._rotation, rad);
    };

    Transform.prototype.getMatrix = function(dst) {
      if (dst == null) {
        dst = mat4.create();
      }
      return mat4.fromRotationTranslationScale(dst, this._rotation, this._translation, this._scale);
    };

    return Transform;

  })();

  DFIR.SceneNode = (function() {
    function SceneNode(transform, object) {
      this.transform = transform;
      this.object = object != null ? object : null;
      this.localMatrix = mat4.create();
      this.worldMatrix = mat4.create();
      this.children = [];
      this.parent = null;
      this.visible = true;
      if (this.transform == null) {
        this.transform = new DFIR.Transform();
      }
    }

    SceneNode.prototype.translate = function(vec) {
      return this.transform.translate(vec);
    };

    SceneNode.prototype.scale = function(num) {
      return this.transform.scale(num);
    };

    SceneNode.prototype.scaleVector = function(vec) {
      return this.transform.scaleVector(vec);
    };

    SceneNode.prototype.rotateX = function(rad) {
      return this.transform.rotateX(rad);
    };

    SceneNode.prototype.rotateY = function(rad) {
      return this.transform.rotateY(rad);
    };

    SceneNode.prototype.rotateZ = function(rad) {
      return this.transform.rotateZ(rad);
    };

    SceneNode.prototype.walk = function(callback) {
      var child, l, len, ref, results;
      if (this.visible) {
        callback(this);
        ref = this.children;
        results = [];
        for (l = 0, len = ref.length; l < len; l++) {
          child = ref[l];
          results.push(child.walk(callback));
        }
        return results;
      }
    };

    SceneNode.prototype.addChild = function(child) {
      return child.setParent(this);
    };

    SceneNode.prototype.setParent = function(parent) {
      if (parent == null) {
        return;
      }
      if (this.parent && indexOf.call(this.parent.children, this) >= 0) {
        this.parent.children = this.parent.chilren.filter(function(child) {
          return child !== this;
        });
      }
      if (parent.children != null) {
        parent.children.push(this);
      }
      return this.parent = parent;
    };

    SceneNode.prototype.updateWorldMatrix = function(parentMatrix) {
      var child, l, len, ref, results;
      mat4.copy(this.localMatrix, this.transform.getMatrix());
      if (parentMatrix) {
        mat4.multiply(this.worldMatrix, parentMatrix, this.localMatrix);
      } else {
        mat4.copy(this.worldMatrix, this.localMatrix);
      }
      ref = this.children;
      results = [];
      for (l = 0, len = ref.length; l < len; l++) {
        child = ref[l];
        results.push(child.updateWorldMatrix(this.worldMatrix));
      }
      return results;
    };

    SceneNode.prototype.attach = function(object) {
      this.object = object;
    };

    return SceneNode;

  })();

  DFIR.Scene = (function() {
    function Scene() {
      this.root = new DFIR.SceneNode();
      this.directionalLights = [];
      this.pointLights = [];
      this.spotLights = [];
    }

    return Scene;

  })();

  DFIR.Renderer = (function() {
    function Renderer(canvas, post_process_enabled) {
      this.post_process_enabled = post_process_enabled != null ? post_process_enabled : false;
      this.ready = false;
      this.debug_view = 0;
      this.width = canvas ? canvas.width : window.innerWidth;
      this.height = canvas ? canvas.height : window.innerHeight;
      this.exposure = 1.0;
      if (canvas == null) {
        canvas = document.createElement('canvas');
        document.body.appendChild(canvas);
      }
      canvas.width = this.width;
      canvas.height = this.height;
      DFIR.gl = window.gl = canvas.getContext("webgl");
      gl.viewportWidth = canvas.width;
      gl.viewportHeight = canvas.height;
      this.canvas = canvas;
      this.gbuffer = new DFIR.Gbuffer(1.0);
      this.createTargets();
      this.setDefaults();
      this.drawCallCount = 0;
      this.tonemap = 0;
    }

    Renderer.prototype.checkReadiness = function() {
      if ((this.quad != null) && (this.outputQuad != null)) {
        return this.ready = true;
      }
    };

    Renderer.prototype.createTargets = function() {
      var status;
      this.accumulationTexture = this.gbuffer.createTexture();
      this.frameBuffer = gl.createFramebuffer();
      gl.bindFramebuffer(gl.FRAMEBUFFER, this.frameBuffer);
      gl.bindTexture(gl.TEXTURE_2D, this.accumulationTexture);
      gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, this.accumulationTexture, 0);
      status = gl.checkFramebufferStatus(gl.FRAMEBUFFER);
      console.log("Final FrameBuffer status after initialization: " + status);
      gl.bindFramebuffer(gl.FRAMEBUFFER, null);
      gl.bindTexture(gl.TEXTURE_2D, null);
      DFIR.ShaderLoader.load('shaders/fs_quad_vert.glsl', 'shaders/fs_quad_frag.glsl', (function(_this) {
        return function(program) {
          _this.quad = new DFIR.FullscreenQuad();
          _this.quad.setMaterial(new DFIR.Shader(program));
          _this.quad.material.showInfo();
          return _this.checkReadiness();
        };
      })(this));
      return DFIR.ShaderLoader.load('shaders/fs_quad_vert.glsl', 'shaders/post_process_frag.glsl', (function(_this) {
        return function(program) {
          _this.outputQuad = new DFIR.FullscreenQuad();
          _this.outputQuad.setMaterial(new DFIR.Shader(program));
          return _this.checkReadiness();
        };
      })(this));
    };

    Renderer.prototype.setDefaults = function() {
      gl.clearColor(0.0, 0.0, 0.0, 1.0);
      gl.enable(gl.DEPTH_TEST);
      gl.depthFunc(gl.LEQUAL);
      gl.depthMask(true);
      gl.clearDepth(1.0);
      gl.enable(gl.BLEND);
      gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
      return gl.enable(gl.CULL_FACE);
    };

    Renderer.prototype.enableGBuffer = function() {
      this.gbuffer.bind();
      gl.cullFace(gl.BACK);
      gl.enable(gl.BLEND);
      gl.blendFunc(gl.ONE, gl.ZERO);
      gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
      return gl.enable(gl.CULL_FACE);
    };

    Renderer.prototype.updateGBuffer = function(scene, camera) {
      var dc;
      this.enableGBuffer();
      camera.updateViewMatrix();
      camera.updateProjectionMatrix();
      scene.root.updateWorldMatrix();
      dc = 0;
      scene.root.walk(function(node) {
        if (node.object != null) {
          if (node.object.bind()) {
            node.object.draw(camera, node.worldMatrix);
            node.object.release();
            return dc++;
          }
        }
      });
      this.drawCallCount = dc;
      return this.gbuffer.release();
    };

    Renderer.prototype.doLighting = function(scene, camera) {
      var l, len, light, ref;
      gl.enable(gl.BLEND);
      if (this.post_process_enabled) {
        gl.bindFramebuffer(gl.FRAMEBUFFER, this.frameBuffer);
        gl.clearColor(0.0, 0.0, 0.0, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);
      }
      this.quad.material.use();
      this.quad.bind();
      gl.activeTexture(gl.TEXTURE0);
      gl.bindTexture(gl.TEXTURE_2D, this.gbuffer.getDepthTextureUnit());
      gl.activeTexture(gl.TEXTURE1);
      gl.bindTexture(gl.TEXTURE_2D, this.gbuffer.getNormalsTextureUnit());
      gl.activeTexture(gl.TEXTURE2);
      gl.bindTexture(gl.TEXTURE_2D, this.gbuffer.getAlbedoTextureUnit());
      gl.uniform1i(this.quad.material.getUniform('depthTexture'), 0);
      gl.uniform1i(this.quad.material.getUniform('normalsTexture'), 1);
      gl.uniform1i(this.quad.material.getUniform('albedoTexture'), 2);
      gl.uniformMatrix4fv(this.quad.material.getUniform('uViewMatrix'), false, camera.getViewMatrix());
      gl.uniformMatrix4fv(this.quad.material.getUniform('uViewProjectionMatrix'), false, camera.getViewProjectionMatrix());
      gl.uniformMatrix4fv(this.quad.material.getUniform('inverseProjectionMatrix'), false, camera.getInverseProjectionMatrix());
      gl.uniformMatrix4fv(this.quad.material.getUniform('inverseViewProjectionMatrix'), false, camera.getInverseViewProjectionMatrix());
      gl.uniform1i(this.quad.material.getUniform('DEBUG'), this.debug_view);
      gl.uniform1f(this.quad.material.getUniform('exposure'), this.exposure);
      if (this.debug_view === 0) {
        gl.enable(gl.BLEND);
        gl.blendFunc(gl.ONE, gl.ONE);
        ref = scene.directionalLights;
        for (l = 0, len = ref.length; l < len; l++) {
          light = ref[l];
          gl.uniform3fv(this.quad.material.getUniform('lightDirection'), light.position);
          gl.uniform3fv(this.quad.material.getUniform('lightColor'), light.color);
          gl.uniform1f(this.quad.material.getUniform('lightStrength'), light.strength);
          gl.uniform1f(this.quad.material.getUniform('lightAttenuation'), light.attenuation);
          gl.drawArrays(gl.TRIANGLES, 0, this.quad.vertexBuffer.numItems);
        }
      } else {
        gl.disable(gl.BLEND);
        gl.blendFunc(gl.ONE, gl.ZERO);
        gl.drawArrays(gl.TRIANGLES, 0, this.quad.vertexBuffer.numItems);
      }
      this.quad.release();
      if (this.post_process_enabled) {
        return gl.bindFramebuffer(gl.FRAMEBUFFER, null);
      }
    };

    Renderer.prototype.doPostProcess = function(scene, camera) {
      this.setDefaults();
      this.outputQuad.material.use();
      this.outputQuad.bind();
      gl.activeTexture(gl.TEXTURE0);
      gl.bindTexture(gl.TEXTURE_2D, this.accumulationTexture);
      gl.uniform1i(this.outputQuad.material.getUniform('renderTexture'), 0);
      gl.uniform1i(this.outputQuad.material.getUniform('DEBUG'), this.debug_view);
      gl.uniform1f(this.outputQuad.material.getUniform('exposure'), this.exposure);
      gl.uniform1i(this.outputQuad.material.getUniform('tonemap'), this.tonemap);
      gl.drawArrays(gl.TRIANGLES, 0, this.quad.vertexBuffer.numItems);
      return this.outputQuad.release();
    };

    Renderer.prototype.reset = function() {
      gl.viewport(0, 0, this.width, this.height);
      gl.enable(gl.DEPTH_TEST);
      return gl.enable(gl.CULL_FACE);
    };

    Renderer.prototype.draw = function(scene, camera) {
      if (this.ready) {
        this.reset();
        this.updateGBuffer(scene, camera);
        this.doLighting(scene, camera);
        if (this.post_process_enabled) {
          return this.doPostProcess(scene, camera);
        }
      }
    };

    return Renderer;

  })();

}).call(this);

//# sourceMappingURL=main.js.map
