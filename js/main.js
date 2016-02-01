(function() {
  var DebugView, buildProgram, buildProgramFromStrings, buildShaderProgram, exports, fs_quad_fragment_shader, fs_quad_vertex_shader, getShader, getShaderParams, loadJSON, loadResource, loadShaderAjax, loadTexture, mergeVertices, pixelsToClip, shader_type_enums,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  exports = typeof exports !== 'undefined' ? exports : window;

  exports.DFIR = {};

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
    function Buffer(data, itemSize, mode, type) {
      this.itemSize = itemSize;
      if (type == null) {
        type = gl.ARRAY_BUFFER;
      }
      this.buffer = gl.createBuffer();
      gl.bindBuffer(type, this.buffer);
      gl.bufferData(type, data, mode);
      this.numItems = data.length / this.itemSize;
    }

    Buffer.prototype.bind = function() {
      return gl.bindBuffer(this.buffer);
    };

    Buffer.prototype.get = function() {
      return this.buffer;
    };

    Buffer.prototype.release = function() {
      return gl.bindBuffer(null);
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
      this.scale = vec3.create();
      vec3.set(this.scale, 1.0, 1.0, 1.0);
      this.transformDirty = true;
      this.worldTransform = mat4.create();
      this.worldViewMatrix = mat4.create();
      this.normalMatrix = mat3.create();
      this.worldViewProjectionMatrix = mat4.create();
      this.children = [];
      this.visible = true;
    }

    Object3D.prototype.getWorldTransform = function() {
      if (this.transformDirty === true) {
        this.updateWorldTransform();
      }
      return this.worldTransform;
    };

    Object3D.prototype.getNormalMatrix = function(viewMatrix) {
      var normalMatrix;
      normalMatrix = mat3.create();
      mat3.getInverse(normalMatrix, viewMatrix);
      mat3.transpose(normalMatrix, normalMatrix);
      return normalMatrix;
    };

    Object3D.prototype.draw = function(camera) {
      if (!this.material || !this.loaded) {
        return;
      }
      this.material.use();
      this.updateWorldTransform();
      mat4.multiply(this.worldViewMatrix, camera.getViewMatrix(), this.worldTransform);
      mat3.normalFromMat4(this.normalMatrix, this.worldViewMatrix);
      this.setMatrixUniforms(camera);
      this.bindTextures();
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

    Object3D.prototype.setMatrixUniforms = function(camera) {
      if (!this.material) {
        return null;
      }
      gl.uniformMatrix4fv(this.material.getUniform('uMVMatrix'), false, this.worldViewMatrix);
      gl.uniformMatrix4fv(this.material.getUniform('uPMatrix'), false, camera.getProjectionMatrix());
      gl.uniformMatrix4fv(this.material.getUniform('uViewMatrix'), false, camera.getViewMatrix());
      gl.uniformMatrix3fv(this.material.getUniform('uNormalMatrix'), false, this.normalMatrix);
      return this.setFloatUniform('farClip', camera.far);
    };

    Object3D.prototype.updateWorldTransform = function(parentTransform) {
      mat4.identity(this.worldTransform);
      mat4.translate(this.worldTransform, this.worldTransform, this.position);
      mat4.scale(this.worldTransform, this.worldTransform, this.scale);
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

    Object3D.prototype.visit = function(func) {
      var c, j, len, ref, results;
      if (!this.visible) {
        return;
      }
      func(this);
      ref = this.children;
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        c = ref[j];
        results.push(c.visit(func));
      }
      return results;
    };

    Object3D.prototype.update = function() {
      if (this.transformDirty) {
        mat4.fromRotationTranslation(this.transform, this.rotationQuaternion, this.position);
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

    return Scene;

  })(DFIR.Object3D);

  DFIR.Mesh = (function(superClass) {
    extend(Mesh, superClass);

    function Mesh(geometry, shader1) {
      this.geometry = geometry;
      this.shader = shader1;
      Mesh.__super__.constructor.call(this);
      if (this.geometry == null) {
        this.geometry = new DFIR.Geometry();
      }
      if (this.shader == null) {
        this.shader = new DFIR.BasicShader();
      }
    }

    return Mesh;

  })(DFIR.Object3D);

  mergeVertices = function(vertices, faces) {
    var changes, i, j, key, precision, precisionPoints, ref, results, unique, v, verticesMap;
    verticesMap = {};
    unique = [];
    changes = [];
    precisionPoints = 4;
    precision = Math.pow(10, precisionPoints);
    results = [];
    for (i = j = 0, ref = vertices.length; j < ref; i = j += 1) {
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

  loadJSON = function(url, callback) {
    var key, request;
    key = md5(url);
    console.log(key);
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
      this.onDataLoaded = bind(this.onDataLoaded, this);
      JSONGeometry.__super__.constructor.call(this);
      loadJSON(url, this.onDataLoaded);
      this.material = null;
      this.loaded = false;
    }

    JSONGeometry.prototype.setMaterial = function(shader) {
      return this.material = shader;
    };

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

    JSONGeometry.prototype.setFloatUniform = function(name, val) {
      return gl.uniform1f(this.material.getUniform(name), val);
    };

    JSONGeometry.prototype.setVec4Uniform = function(name, x, y, z, w) {
      return gl.uniform4f(this.material.getUniform(name), x, y, z, w);
    };

    JSONGeometry.prototype.onDataLoaded = function(data) {
      this.vertexPositionBuffer = new DFIR.Buffer(new Float32Array(data.vertexPositions), 3, gl.STATIC_DRAW);
      this.vertexTextureCoordBuffer = new DFIR.Buffer(new Float32Array(data.vertexTextureCoords), 2, gl.STATIC_DRAW);
      this.vertexNormalBuffer = new DFIR.Buffer(new Float32Array(data.vertexNormals), 3, gl.STATIC_DRAW);
      this.vertexIndexBuffer = new DFIR.Buffer(new Uint16Array(data.indices), 1, gl.STATIC_DRAW, gl.ELEMENT_ARRAY_BUFFER);
      return this.loaded = true;
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
      var fragShader;
      fragShader = gl.createShader(gl.FRAGMENT_SHADER);
      gl.shaderSource(fragShader, data);
      gl.compileShader(fragShader);
      console.log(gl.getShaderInfoLog(fragShader));
      this.result.fragmentSource = fragShader;
      this.fragmentLoaded = true;
      if (this.checkLoaded()) {
        return this.callback(this.buildShader());
      }
    };

    ShaderLoader.prototype.onVertexLoaded = function(data) {
      var vertShader;
      vertShader = gl.createShader(gl.VERTEX_SHADER);
      gl.shaderSource(vertShader, data);
      gl.compileShader(vertShader);
      console.log(gl.getShaderInfoLog(vertShader));
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
    var shaderProgram;
    shaderProgram = gl.createProgram();
    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragmentShader);
    gl.linkProgram(shaderProgram);
    console.log(gl.getProgramInfoLog(shaderProgram));
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
    var activeAttributes, activeUniforms, attribute, i, j, l, ref, ref1, result, uniform;
    gl.useProgram(program);
    result = {
      attributes: [],
      uniforms: [],
      attributeCount: 0,
      uniformCount: 0
    };
    activeUniforms = gl.getProgramParameter(program, gl.ACTIVE_UNIFORMS);
    activeAttributes = gl.getProgramParameter(program, gl.ACTIVE_ATTRIBUTES);
    for (i = j = 0, ref = activeUniforms; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
      uniform = gl.getActiveUniform(program, i);
      uniform.typeName = shader_type_enums[uniform.type];
      result.uniforms.push(uniform);
      result.uniformCount += uniform.size;
    }
    for (i = l = 0, ref1 = activeAttributes; 0 <= ref1 ? l < ref1 : l > ref1; i = 0 <= ref1 ? ++l : --l) {
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
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
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

  DFIR.Shader = (function() {
    function Shader(program1) {
      this.program = program1;
      this.params = getShaderParams(this.program);
      this.diffuseMapLoaded = this.normalMapLoaded = false;
      this.buildUniforms();
      this.buildAttributes();
    }

    Shader.prototype.buildUniforms = function() {
      var j, len, ref, results, u;
      this.uniforms = {};
      ref = this.params.uniforms;
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        u = ref[j];
        results.push(this.uniforms[u.name] = gl.getUniformLocation(this.program, u.name));
      }
      return results;
    };

    Shader.prototype.buildAttributes = function() {
      var a, j, len, ref, results;
      this.attributes = {};
      ref = this.params.attributes;
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        a = ref[j];
        results.push(this.attributes[a.name] = gl.getAttribLocation(this.program, a.name));
      }
      return results;
    };

    Shader.prototype.use = function() {
      return gl.useProgram(this.program);
    };

    Shader.prototype.showInfo = function() {
      console.log(this.name);
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

  DFIR.Camera = (function(superClass) {
    extend(Camera, superClass);

    function Camera(viewportWidth, viewportHeight) {
      this.viewportWidth = viewportWidth;
      this.viewportHeight = viewportHeight;
      Camera.__super__.constructor.call(this);
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
      this.near = 0.01;
      this.far = 60.0;
      this.updateViewMatrix();
      this.projectionMatrix = mat4.create();
      this.updateProjectionMatrix();
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

    Camera.prototype.updateViewMatrix = function() {
      mat4.identity(this.viewMatrix);
      return mat4.lookAt(this.viewMatrix, this.position, this.target, this.up);
    };

    Camera.prototype.updateProjectionMatrix = function() {
      var aspect;
      mat4.identity(this.projectionMatrix);
      aspect = this.viewportWidth / this.viewportHeight;
      return mat4.perspective(this.projectionMatrix, this.fov, aspect, this.near, this.far);
    };

    return Camera;

  })(DFIR.Object3D);

  DFIR.DirectionalLight = (function(superClass) {
    extend(DirectionalLight, superClass);

    function DirectionalLight() {
      return DirectionalLight.__super__.constructor.apply(this, arguments);
    }

    DirectionalLight.prototype.bind = function(uniforms) {
      gl.uniform3fv(uniforms.lightColor, this.color);
      return gl.uniform3fv(uniforms.lightDirection, this.direction);
    };

    return DirectionalLight;

  })(DFIR.Object3D);

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
      this.mrt_ext = gl.getExtension('WEBGL_draw_buffers');
      this.half_ext = gl.getExtension("OES_texture_half_float");
      this.depth_ext = gl.getExtension("WEBKIT_WEBGL_depth_texture") || gl.getExtension("WEBGL_depth_texture");
      this.frameBuffer = gl.createFramebuffer();
      gl.bindFramebuffer(gl.FRAMEBUFFER, this.frameBuffer);
      this.albedoTextureUnit = this.createTexture();
      this.normalsTextureUnit = this.createTexture(half_ext.HALF_FLOAT_OES);
      this.depthComponent = this.createDepthTexture();
      gl.framebufferTexture2D(gl.FRAMEBUFFER, this.mrt_ext.COLOR_ATTACHMENT0_WEBGL, gl.TEXTURE_2D, this.albedoTextureUnit, 0);
      gl.framebufferTexture2D(gl.FRAMEBUFFER, this.mrt_ext.COLOR_ATTACHMENT1_WEBGL, gl.TEXTURE_2D, this.normalsTextureUnit, 0);
      gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.TEXTURE_2D, this.depthComponent, 0);
      console.log("GBuffer FrameBuffer status after initialization: ");
      console.log(gl.checkFramebufferStatus(gl.FRAMEBUFFER) === gl.FRAMEBUFFER_COMPLETE);
      this.mrt_ext.drawBuffersWEBGL([this.mrt_ext.COLOR_ATTACHMENT0_WEBGL, this.mrt_ext.COLOR_ATTACHMENT1_WEBGL]);
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
      format = this.half_ext.HALF_FLOAT_OES;
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
      return gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    };

    Gbuffer.prototype.release = function() {
      gl.bindTexture(gl.TEXTURE_2D, null);
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
      var current_level, f, ht, indices, j, ref, texcoords, verts, wd, x, y;
      x = -1.0;
      y = -1.0;
      ht = 2.0 / num_levels;
      wd = 0.5;
      this.vertices = [];
      this.textureCoords = [];
      this.indices = [];
      f = 0;
      for (current_level = j = 1, ref = num_levels; 1 <= ref ? j <= ref : j >= ref; current_level = 1 <= ref ? ++j : --j) {
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
      var i, j, ref, results;
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
      for (i = j = 0, ref = this.quads.length; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
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

}).call(this);
