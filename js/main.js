(function() {
  var buildProgram, exports, fs_quad_fragment_shader, fs_quad_vertex_shader, gbuffer_frag, gbuffer_vert, getShader, getShaderParams, loadJSON, loadTexture, shader_type_enums,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  exports = typeof exports !== 'undefined' ? exports : window;

  exports.DFIR = {};

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

  DFIR.Object3D = (function() {
    function Object3D() {
      this.position = vec3.create();
      this.scale = vec3.create();
      this.rotationQuaternion = quat.create();
      this.transformDirty = false;
      this.transform = mat4.create();
      this.children = [];
      this.visible = true;
    }

    Object3D.prototype.setPosition = function(pos) {
      this.position.x = pos.x;
      this.position.y = pos.y;
      this.position.z = pos.z;
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

  loadJSON = function(url, callback) {
    var request;
    request = new XMLHttpRequest();
    request.open('GET', url);
    console.log("Loading json: " + url);
    request.onreadystatechange = function() {
      if (request.readyState === 4) {
        return callback(JSON.parse(request.responseText));
      }
    };
    return request.send();
  };

  DFIR.JSONGeometry = (function(superClass) {
    extend(JSONGeometry, superClass);

    function JSONGeometry(url) {
      this.onDataLoaded = bind(this.onDataLoaded, this);
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

    JSONGeometry.prototype.setMatrixUniforms = function(mvMatrix, pMatrix) {
      if (!this.material) {
        return null;
      }
      gl.uniformMatrix4fv(this.material.getUniform('uMVMatrix'), false, mvMatrix);
      return gl.uniformMatrix4fv(this.material.getUniform('uPMatrix'), false, pMatrix);
    };

    JSONGeometry.prototype.setFloatUniform = function(name, val) {
      return gl.uniform1f(this.material.getUniform(name), val);
    };

    JSONGeometry.prototype.setVec4Uniform = function(name, x, y, z, w) {
      return gl.uniform4f(this.material.getUniform(name), x, y, z, w);
    };

    JSONGeometry.prototype.draw = function() {
      if (!this.material || !this.loaded) {
        return;
      }
      gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.vertexIndexBuffer.get());
      return gl.drawElements(gl.TRIANGLES, this.vertexIndexBuffer.numItems, gl.UNSIGNED_SHORT, 0);
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
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      console.log(id, gl.getShaderInfoLog(shader));
      return null;
    }
    return shader;
  };

  buildProgram = function(vertexSourceId, fragmentSourceId) {
    var fragmentShader, shaderProgram, vertexShader;
    fragmentShader = getShader(fragmentSourceId);
    vertexShader = getShader(vertexSourceId);
    shaderProgram = gl.createProgram();
    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragmentShader);
    gl.linkProgram(shaderProgram);
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
    function Shader(vertSourceId, fragSourceId) {
      this.name = vertSourceId;
      this.program = buildProgram(vertSourceId, fragSourceId);
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

  gbuffer_vert = "\nattribute vec3 aVertexNormal;\nattribute vec3 aVertexPosition;\nattribute vec2 aVertexTextureCoords;\n\nuniform mat4 uMVMatrix;\nuniform mat4 uPMatrix;\n\nvarying vec2 vTexCoords;\nvarying float depth;\nvarying vNormal;\n\nvoid main (void) {\n    vTexCoords = aVertexTextureCoords;\n    gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);    \n    depth = gl_Position.z;\n    vec4 n = uMVMatrix * vec4(aVertexNormal, 1.0);\n    vNormal = vec3(n.xyz);\n}";

  gbuffer_frag = "#extension GL_EXT_draw_buffers : require\nprecision mediump float;\nvarying vec3 vNormal;\nvarying vec2 vTexCoords;\nvarying float depth;\n\nuniform float farClip;\nuniform float nearClip;\n\nvec4 pack (float depth) {\n  const vec4 bitSh = vec4(\n    256*256*256,\n    256*256,\n    256,\n    1.0\n  );\n  \n  const vec4 bitMask = vec4 (\n    0.0,\n    1.0 / 256.0,\n    1.0 / 256.0,\n    1.0 / 256.0\n  );\n  \n  vec4 comp = fract(depth * bitSh);\n  comp -= comp.xxyz * bitMask;\n  return comp;\n}\n\n\nvoid main (void) {\n  gl_FragData[0] = vec4(0.5,0.5,0.5,1.0);\n  gl_FragData[1] = vec4(vNormal, 1.0);\n  gl_FragData[2] = pack(1.0 - depth/farClip);\n}";

  DFIR.Gbuffer = (function() {
    function Gbuffer(resolution) {
      this.resolution = resolution != null ? resolution : 1.0;
      this.width = gl.viewportWidth / this.resolution;
      this.height = gl.viewportHeight / this.resolution;
      this.createFrameBuffer();
    }

    Gbuffer.prototype.createFrameBuffer = function() {
      this.ext = gl.getExtension('WEBGL_draw_buffers');
      this.DepthEXT = gl.getExtension("WEBKIT_WEBGL_depth_texture") || gl.getExtension("WEBGL_depth_texture");
      this.frameBuffer = gl.createFramebuffer();
      gl.bindFramebuffer(gl.FRAMEBUFFER, this.frameBuffer);
      this.albedoTextureUnit = this.createTexture();
      this.normalsTextureUnit = this.createTexture();
      this.depthTextureUnit = this.createTexture();
      this.depthComponent = this.createDepthTexture();
      gl.framebufferTexture2D(gl.FRAMEBUFFER, this.ext.COLOR_ATTACHMENT0_WEBGL, gl.TEXTURE_2D, this.albedoTextureUnit, 0);
      gl.framebufferTexture2D(gl.FRAMEBUFFER, this.ext.COLOR_ATTACHMENT1_WEBGL, gl.TEXTURE_2D, this.normalsTextureUnit, 0);
      gl.framebufferTexture2D(gl.FRAMEBUFFER, this.ext.COLOR_ATTACHMENT2_WEBGL, gl.TEXTURE_2D, this.depthTextureUnit, 0);
      gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.TEXTURE_2D, this.depthComponent, 0);
      console.log("GBuffer FrameBuffer status after initialization: ");
      console.log(gl.checkFramebufferStatus(gl.FRAMEBUFFER) === gl.FRAMEBUFFER_COMPLETE);
      this.ext.drawBuffersWEBGL([this.ext.COLOR_ATTACHMENT0_WEBGL, this.ext.COLOR_ATTACHMENT1_WEBGL, this.ext.COLOR_ATTACHMENT2_WEBGL]);
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

    Gbuffer.prototype.createTexture = function() {
      var tex;
      tex = gl.createTexture();
      gl.bindTexture(gl.TEXTURE_2D, tex);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, this.width, this.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
      return tex;
    };

    Gbuffer.prototype.bind = function() {
      return gl.bindFramebuffer(gl.FRAMEBUFFER, this.frameBuffer);
    };

    Gbuffer.prototype.release = function() {
      gl.bindTexture(gl.TEXTURE_2D, null);
      return gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    };

    Gbuffer.prototype.getDepthTextureUnit = function() {
      return this.depthTextureUnit;
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

  DFIR.FullscreenQuad = (function() {
    function FullscreenQuad() {
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

  })();

}).call(this);
