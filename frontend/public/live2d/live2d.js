(function () {
  if (window.live2d_initialized) {
    return;
  }
  window.live2d_initialized = true;

  var scriptTag = document.currentScript || document.querySelector('script[src*="/live2d/live2d.js"]');
  var basePath = scriptTag ? scriptTag.getAttribute('src').replace(/live2d\.js.*$/, '') : '/live2d/';

  function loadExternalResource(url, type) {
    return new Promise(function (resolve, reject) {
      var tag;
      if (type === 'css') {
        tag = document.createElement('link');
        tag.rel = 'stylesheet';
        tag.href = url;
      } else {
        tag = document.createElement('script');
        tag.src = url;
        tag.async = false;
      }
      tag.onload = function () {
        resolve(url);
      };
      tag.onerror = function () {
        reject(new Error('Live2D resource failed: ' + url));
      };
      document.head.appendChild(tag);
    });
  }

  function ensureDefaultModel(modelConfig) {
    if (!modelConfig) {
      return;
    }
    if (typeof modelConfig.defaultModelId !== 'undefined') {
      localStorage.setItem('modelId', String(modelConfig.defaultModelId));
    }
    if (typeof modelConfig.defaultTextureId !== 'undefined') {
      localStorage.setItem('modelTexturesId', String(modelConfig.defaultTextureId));
    }
  }

  function normalizeCdnPath(path) {
    if (!path) {
      return '';
    }
    return path.endsWith('/') ? path : path + '/';
  }

  function loadSiteSettings() {
    return fetch('/api/public/settings/site')
      .then(function (response) {
        return response.ok ? response.json() : null;
      })
      .then(function (payload) {
        return payload && payload.data ? payload.data : null;
      })
      .catch(function () {
        return null;
      });
  }

  function initLive2d() {
    if (document.getElementById('waifu') || document.getElementById('waifu-toggle')) {
      return;
    }

    Promise.all([
      fetch(basePath + 'live2d.json').then(function (response) {
        return response.json();
      }),
      loadSiteSettings()
    ])
      .then(function (results) {
        var userConfig = results[0];
        var siteSettings = results[1] || {};

        if (siteSettings.live2dEnabled === false || siteSettings.live2dEnabled === 'false') {
          return null;
        }

        var runtime = userConfig.runtime || {};
        var runtimeType = runtime.type || 'cubism';
        var widgetPath = normalizeCdnPath(runtime.widgetPath || userConfig.base.cdnPath);
        var cdnPath = normalizeCdnPath(siteSettings.live2dCdnPath || userConfig.base.cdnPath);
        var modelConfig = {
          defaultModelId: typeof siteSettings.live2dModelId === 'number' ? siteSettings.live2dModelId : userConfig.model.defaultModelId,
          defaultTextureId: typeof siteSettings.live2dTextureId === 'number' ? siteSettings.live2dTextureId : userConfig.model.defaultTextureId
        };
        var tools = userConfig.tools || ['hitokoto', 'express', 'switch-model', 'switch-texture', 'info', 'quit'];
        var resources = runtimeType === 'classic'
          ? [
              loadExternalResource(widgetPath + 'waifu.css', 'css'),
              loadExternalResource(widgetPath + 'live2d.min.js', 'js'),
              loadExternalResource(widgetPath + 'waifu-tips.js', 'js')
            ]
          : [
              loadExternalResource(cdnPath + 'Core/waifu.css', 'css'),
              loadExternalResource(cdnPath + 'Core/live2dcubismcore.js', 'js'),
              loadExternalResource(cdnPath + 'Core/live2d-sdk.js', 'js'),
              loadExternalResource(cdnPath + 'Core/waifu-tips.js', 'js')
            ];

        return Promise.all(resources).then(function () {
          ensureDefaultModel(modelConfig);

          if (typeof initWidget === 'undefined') {
            throw new Error('Live2D widget core is not available');
          }

          initWidget({
            homePath: userConfig.base.homePath || '/',
            waifuPath: basePath + 'config/waifu-tips.json',
            cdnPath: cdnPath,
            tools: tools,
            dragEnable: Boolean(userConfig.drag && userConfig.drag.enable),
            dragDirection: userConfig.drag && userConfig.drag.direction ? userConfig.drag.direction : ['x', 'y'],
            switchType: userConfig.switchType || 'order'
          });

          loadExternalResource(basePath + 'smart-tips.js', 'js').catch(function (error) {
            console.warn('Live2D 智能提示加载失败:', error);
          });
        });
      })
      .catch(function (error) {
        console.error('Live2D 初始化失败:', error);
      });
  }

  function scheduleInit() {
    if (window.matchMedia && window.matchMedia('(max-width: 767px)').matches) {
      return;
    }
    if (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      return;
    }
    if (window.requestIdleCallback) {
      window.requestIdleCallback(initLive2d, { timeout: 2500 });
      return;
    }
    window.setTimeout(initLive2d, 800);
  }

  if (document.readyState === 'complete') {
    scheduleInit();
  } else {
    window.addEventListener('load', scheduleInit, { once: true });
  }
})();
