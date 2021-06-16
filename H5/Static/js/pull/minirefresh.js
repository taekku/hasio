/*!
 * minirefresh v2.0.2
 * (c) 2017-2018 dailc
 * Released under the MIT License.
 * https://github.com/minirefresh/minirefresh
 */

(function (global, factory) {
	typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
	typeof define === 'function' && define.amd ? define(factory) :
	(global.MiniRefreshTools = factory());
}(this, (function () { 'use strict';

function getNow() {
    return window.performance && (window.performance.now ? window.performance.now() + window.performance.timing.navigationStart : +new Date());
}

var noop = function noop() {};

function isArray(object) {
    if (Array.isArray) {
        return Array.isArray(object);
    }

    return object instanceof Array;
}

function isObject(object) {
    var classType = Object.prototype.toString.call(object).match(/^\[object\s(.*)\]$/)[1];

    return classType !== 'String' && classType !== 'Number' && classType !== 'Boolean' && classType !== 'Undefined' && classType !== 'Null';
}

function isWindow(object) {
    return object && object === window;
}

function isPlainObject(obj) {
    return isObject(obj) && !isWindow(obj)
    // 如果不是普通的object,Object.prototype需要通过链回溯才能得到
    && Object.getPrototypeOf(obj) === Object.prototype;
}

function extend() {
    var _arguments = arguments;

    var len = arguments.length;
    var target = (arguments.length <= 0 ? undefined : arguments[0]) || {};
    var sourceIndex = 1;
    var isDeep = false;

    if (typeof target === 'boolean') {
        // 深赋值或false
        isDeep = target;
        target = (arguments.length <= sourceIndex ? undefined : arguments[sourceIndex]) || {};
        sourceIndex++;
    }

    if (!isObject(target)) {
        // 确保拓展的一定是object
        target = {};
    }

    var _loop = function _loop() {
        // source的拓展
        var source = _arguments.length <= sourceIndex ? undefined : _arguments[sourceIndex];

        if (source && isObject(source)) {
            // for-of打包过大
            Object.keys(source).forEach(function (name) {
                var src = target[name];
                var copy = source[name];
                var copyIsPlainObject = isPlainObject(copy);
                var copyIsArray = isArray(copy);
                var clone = void 0;

                if (target === copy) {
                    // 防止环形引用
                    return;
                }

                if (isDeep && copy && (copyIsArray || copyIsPlainObject)) {
                    // 这里必须用isPlainObject,只有同样是普通的object才会复制继承
                    // 如果是FormData之流的，会走后面的覆盖路线
                    if (copyIsArray) {
                        copyIsArray = false;
                        clone = src && isArray(src) ? src : [];
                    } else {
                        clone = src && isPlainObject(src) ? src : {};
                    }

                    target[name] = extend(isDeep, clone, copy);
                } else if (copy !== undefined) {
                    // 如果非深赋值
                    // 或者不是普通的object，直接覆盖，例如FormData之类的也会覆盖
                    target[name] = copy;
                }
            });
        }
    };

    for (; sourceIndex < len; sourceIndex++) {
        _loop();
    }

    return target;
}

/**
 * 选择这段代码用到的太多了，因此抽取封装出来
 * @param {Object} element dom元素或者selector
 * @return {HTMLElement} 返回选择的Dom对象，无果没有符合要求的，则返回null
 */
function selector(element) {
    var target = element;

    if (typeof target === 'string') {
        target = document.querySelector(target);
    }

    return target;
}

/**
 * 获取DOM的可视区高度，兼容PC上的body高度获取
 * 因为在通过body获取时，在PC上会有CSS1Compat形式，所以需要兼容
 * @param {HTMLElement} dom 需要获取可视区高度的dom,对body对象有特殊的兼容方案
 * @return {Number} 返回最终的高度
 */
function getClientHeightByDom(dom) {
    var height = dom.clientHeight;

    if (dom === document.body && document.compatMode === 'CSS1Compat') {
        // PC上body的可视区的特殊处理
        height = document.documentElement.clientHeight;
    }

    return height;
}

/**
 * 设置一个Util对象下的命名空间
 * @param {Object} parent 需要绑定到哪一个对象上
 * @param {String} namespace 需要绑定的命名空间名
 * @param {Object} target 需要绑定的目标对象
 * @return {Object} 返回最终的对象
 */
function namespace(parent, namespaceStr, target) {
    if (!namespaceStr) {
        return parent;
    }

    var namespaceArr = namespaceStr.split('.');
    var len = namespaceArr.length;
    var res = parent;

    for (var i = 0; i < len - 1; i += 1) {
        var tmp = namespaceArr[i];

        // 不存在的话要重新创建对象
        res[tmp] = res[tmp] || {};
        // parent要向下一级
        res = res[tmp];
    }
    res[namespaceArr[len - 1]] = target;

    return target;
}

var lang = Object.freeze({
	getNow: getNow,
	noop: noop,
	isArray: isArray,
	isObject: isObject,
	isWindow: isWindow,
	isPlainObject: isPlainObject,
	extend: extend,
	selector: selector,
	getClientHeightByDom: getClientHeightByDom,
	namespace: namespace
});

/**
 * 加入系统判断功能
 */
function osMixin(hybrid) {
    var hybridJs = hybrid;
    var detect = function detect(ua) {
        this.os = {};

        var android = ua.match(/(Android);?[\s/]+([\d.]+)?/);

        if (android) {
            this.os.android = true;
            this.os.version = android[2];
            this.os.isBadAndroid = !/Chrome\/\d/.test(window.navigator.appVersion);
        }

        var iphone = ua.match(/(iPhone\sOS)\s([\d_]+)/);

        if (iphone) {
            this.os.ios = true;
            this.os.iphone = true;
            this.os.version = iphone[2].replace(/_/g, '.');
        }

        var ipad = ua.match(/(iPad).*OS\s([\d_]+)/);

        if (ipad) {
            this.os.ios = true;
            this.os.ipad = true;
            this.os.version = ipad[2].replace(/_/g, '.');
        }

        // quickhybrid的容器
        var quick = ua.match(/QuickHybrid/i);

        if (quick) {
            this.os.quick = true;
        }

        // epoint的容器
        var ejs = ua.match(/EpointEJS/i);

        if (ejs) {
            this.os.ejs = true;
        }

        var dd = ua.match(/DingTalk/i);

        if (dd) {
            this.os.dd = true;
        }

        // 如果ejs和钉钉以及quick都不是，则默认为h5
        if (!ejs && !dd && !quick) {
            this.os.h5 = true;
        }
    };

    detect.call(hybridJs, navigator.userAgent);
}

var DEFAULT_INTERVAL = 1000 / 60;

// 立即执行
var requestAnimationFrame = function () {
    return window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame
    // if all else fails, use setTimeout
    || function requestAnimationFrameTimeOut(callback) {
        // make interval as precise as possible.
        return window.setTimeout(callback, (callback.interval || DEFAULT_INTERVAL) / 2);
    };
}();

var _createClass$1 = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck$1(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

/**
 * 一些事件
 */
var EVENT_INIT = 'initScroll';
var EVENT_SCROLL = 'scroll';
var EVENT_PULL = 'pull';
var EVENT_UP_LOADING = 'upLoading';
var EVENT_RESET_UP_LOADING = 'resetUpLoading';
var EVENT_DOWN_LOADING = 'downLoading';
var EVENT_CANCEL_LOADING = 'cancelLoading';

/**
 * 一些hook
 * hook是指挥它会影响逻辑
 */
var HOOK_BEFORE_DOWN_LOADING = 'beforeDownLoading';

var PER_SECOND = 1000 / 60;

/**
 * 滑动操作相关类
 * 把一些滑动滚动逻辑单独剥离出来
 * 确保Core中只有纯粹的API定义
 */

var Scroll = function () {
    /**
     * 传入minirefresh对象，因为内部一些配置项依赖于minirefresh
     * @param {Object} options 配置信息
     * @constructor
     */
    function Scroll(minirefresh) {
        _classCallCheck$1(this, Scroll);

        this.contentWrap = minirefresh.contentWrap;
        this.scrollWrap = minirefresh.scrollWrap;
        this.options = minirefresh.options;
        this.os = minirefresh.os;
        // 默认没有事件，需要主动绑定
        this.events = {};
        // 默认没有hook
        this.hooks = {};

        // 使用了scrollto后加锁，防止重复
        this.isScrollTo = false;
        // 上拉和下拉的状态
        this.upLoading = false;
        this.downLoading = false;
        // 默认up是没有finish的
        this.isFinishUp = false;

        this._init();
    }

    _createClass$1(Scroll, [{
        key: '_init',
        value: function _init() {
            var _this = this;

            this._initPullDown();
            this._initPullUp();

            setTimeout(function () {
                if (_this.options.down && _this.options.down.isAuto && !_this.options.down.isLock) {
                    // 满足自动下拉,需要判断是否需要动画（仅仅是首次）
                    if (_this.options.down.isAllowAutoLoading) {
                        _this.triggerDownLoading();
                    } else {
                        _this.events[EVENT_DOWN_LOADING] && _this.events[EVENT_DOWN_LOADING](true);
                    }
                } else if (_this.options.up && _this.options.up.isAuto && !_this.options.up.isLock) {
                    // 满足上拉，上拉的配置由配置项决定（每一次）
                    _this.triggerUpLoading();
                }

                _this.events[EVENT_INIT] && _this.events[EVENT_INIT]();
            });
        }
    }, {
        key: 'refreshOptions',
        value: function refreshOptions(options) {
            this.options = options;
        }

        /**
         * ContentWrap的translate动画，用于下拉刷新时进行transform动画
         * @param {Number} y 移动的高度
         * @param {Number} duration 过渡时间
         */

    }, {
        key: 'translateContentWrap',
        value: function translateContentWrap(y, duration) {
            var translateY = y || 0;
            var translateDuration = duration || 0;

            // 改变downHight， 这个参数关乎逻辑
            this.downHight = translateY;

            if (!this.options.down.isScrollCssTranslate) {
                // 只有允许动画时才会scroll也translate,否则只会改变downHeight
                return;
            }

            // 改变wrap的位置（css动画）
            var wrap = this.contentWrap;

            wrap.style.webkitTransitionDuration = translateDuration + 'ms';
            wrap.style.transitionDuration = translateDuration + 'ms';
            wrap.style.webkitTransform = 'translate(0px, ' + translateY + 'px) translateZ(0px)';
            wrap.style.transform = 'translate(0px, ' + translateY + 'px) translateZ(0px)';
        }
    }, {
        key: '_scrollWrapAnimation',
        value: function _scrollWrapAnimation() {
            this.scrollWrap.webkitTransitionTimingFunction = 'cubic-bezier(0.1, 0.57, 0.1, 1)';
            this.scrollWrap.transitionTimingFunction = 'cubic-bezier(0.1, 0.57, 0.1, 1)';
        }
    }, {
        key: '_initPullDown',
        value: function _initPullDown() {
            var _this2 = this;

            // 考虑到options可以更新，所以不能被缓存，而是应该在回调中直接获取
            var scrollWrap = this.scrollWrap;
            var docClientHeight = document.documentElement.clientHeight;

            this._scrollWrapAnimation();

            // 触摸开始
            var touchstartEvent = function touchstartEvent(e) {
                if (_this2.isScrollTo) {
                    // 如果执行滑动事件,则阻止touch事件,优先执行scrollTo方法
                    e.preventDefault();
                }
                // 记录startTop, 并且只有startTop存在值时才允许move
                _this2.startTop = scrollWrap.scrollTop;

                // startY用来计算距离
                _this2.startY = e.touches ? e.touches[0].pageY : e.clientY;
                // X的作用是用来计算方向，如果是横向，则不进行动画处理，避免误操作
                _this2.startX = e.touches ? e.touches[0].pageX : e.clientX;
            };

            scrollWrap.addEventListener('touchstart', touchstartEvent);
            scrollWrap.addEventListener('mousedown', touchstartEvent);

            // 触摸结束
            var touchendEvent = function touchendEvent() {
                var options = _this2.options;

                // 需要重置状态
                if (_this2.isMoveDown) {
                    // 如果下拉区域已经执行动画,则需重置回来
                    if (_this2.downHight >= options.down.offset) {
                        // 符合触发刷新的条件
                        _this2.triggerDownLoading();
                    } else {
                        // 否则默认重置位置
                        _this2.translateContentWrap(0, options.down.bounceTime);
                        _this2.events[EVENT_CANCEL_LOADING] && _this2.events[EVENT_CANCEL_LOADING]();
                    }

                    _this2.isMoveDown = false;
                }

                _this2.startY = 0;
                _this2.startX = 0;
                _this2.preY = 0;
                _this2.startTop = undefined;
                // 当前是否正处于回弹中，常用于iOS中判断，如果先上拉再下拉就处于回弹中（只要moveY为负）
                _this2.isBounce = false;
            };

            scrollWrap.addEventListener('touchend', touchendEvent);
            scrollWrap.addEventListener('mouseup', touchendEvent);
            scrollWrap.addEventListener('mouseleave', touchendEvent);

            // 触摸中
            var touchmoveEvent = function touchmoveEvent(e) {
                var options = _this2.options;
                var isAllowDownloading = true;

                if (_this2.downLoading) {
                    isAllowDownloading = false;
                } else if (!options.down.isAways && _this2.upLoading) {
                    isAllowDownloading = false;
                }

                if (_this2.startTop !== undefined && _this2.startTop <= 0 && isAllowDownloading && !_this2.options.down.isLock) {
                    // 列表在顶部且不在加载中，并且没有锁住下拉动画

                    // 当前第一个手指距离列表顶部的距离
                    var curY = e.touches ? e.touches[0].pageY : e.clientY;
                    var curX = e.touches ? e.touches[0].pageX : e.clientX;

                    // 手指滑出屏幕触发刷新
                    if (curY > docClientHeight) {
                        touchendEvent(e);

                        return;
                    }

                    if (!_this2.preY) {
                        // 设置上次移动的距离，作用是用来计算滑动方向
                        _this2.preY = curY;
                    }

                    // 和上次比,移动的距离 (大于0向下,小于0向上)
                    var diff = curY - _this2.preY;

                    _this2.preY = curY;

                    // 和起点比,移动的距离,大于0向下拉
                    var moveY = curY - _this2.startY;
                    var moveX = curX - _this2.startX;

                    // 如果锁定横向滑动并且横向滑动更多，阻止默认事件
                    if (options.isLockX && Math.abs(moveX) > Math.abs(moveY)) {
                        e.preventDefault();

                        return;
                    }

                    if (_this2.isBounce && _this2.os.ios) {
                        // 暂时iOS中去回弹
                        // 下一个版本中，分开成两种情况，一种是absolute的固定动画，一种是在scrollWrap内部跟随滚动的动画
                        return;
                    }

                    if (moveY > 0) {
                        // 向下拉
                        _this2.isMoveDown = true;

                        // 阻止浏览器的默认滚动事件，因为这时候只需要执行动画即可
                        e.preventDefault();

                        if (!_this2.downHight) {
                            // 下拉区域的高度，用translate动画
                            _this2.downHight = 0;
                        }

                        var downOffset = options.down.offset;
                        var dampRate = 1;

                        if (_this2.downHight < downOffset) {
                            // 下拉距离  < 指定距离
                            dampRate = options.down.dampRateBegin;
                        } else {
                            // 超出了指定距离，随时可以刷新
                            dampRate = options.down.dampRate;
                        }

                        if (diff > 0) {
                            // 需要加上阻尼系数
                            _this2.downHight += diff * dampRate;
                        } else {
                            // 向上收回高度,则向上滑多少收多少高度
                            _this2.downHight += diff;
                        }

                        _this2.events[EVENT_PULL] && _this2.events[EVENT_PULL](_this2.downHight, downOffset);

                        // 执行动画
                        _this2.translateContentWrap(_this2.downHight);
                    } else {
                        _this2.isBounce = true;
                        // 解决嵌套问题。在嵌套有 IScroll，或类似的组件时，这段代码会生效，可以辅助滚动scrolltop
                        // 否则有可能在最开始滚不动
                        if (scrollWrap.scrollTop <= 0) {
                            scrollWrap.scrollTop += Math.abs(diff);
                        }
                    }
                }
            };

            scrollWrap.addEventListener('touchmove', touchmoveEvent);
            scrollWrap.addEventListener('mousemove', touchmoveEvent);
        }
    }, {
        key: '_initPullUp',
        value: function _initPullUp() {
            var _this3 = this;

            var scrollWrap = this.scrollWrap;

            // 如果是Body上的滑动，需要监听window的scroll
            var targetScrollDom = scrollWrap === document.body ? window : scrollWrap;

            targetScrollDom.addEventListener('scroll', function () {
                var scrollTop = scrollWrap.scrollTop;
                var scrollHeight = scrollWrap.scrollHeight;
                var clientHeight = getClientHeightByDom(scrollWrap);
                var options = _this3.options;

                _this3.events[EVENT_SCROLL] && _this3.events[EVENT_SCROLL](scrollTop);

                var isAllowUploading = true;

                if (_this3.upLoading) {
                    isAllowUploading = false;
                } else if (!options.down.isAways && _this3.downLoading) {
                    isAllowUploading = false;
                }

                if (isAllowUploading) {
                    if (!_this3.options.up.isLock && !_this3.isFinishUp && scrollHeight > 0) {
                        var toBottom = scrollHeight - clientHeight - scrollTop;

                        if (toBottom <= options.up.offset) {
                            // 满足上拉加载
                            _this3.triggerUpLoading();
                        }
                    }
                }
            });
        }
    }, {
        key: '_loadFull',
        value: function _loadFull() {
            var _this4 = this;

            var scrollWrap = this.scrollWrap;
            var options = this.options;

            setTimeout(function () {
                // 다음 루프에서 실행
                if (!_this4.options.up.isLock && options.up.loadFull.isEnable
                // 높이를 계산할 수없는 경우 무한로드 방지
                && scrollWrap.scrollTop === 0
                // scrollHeight는 페이지 콘텐츠의 높이입니다 (최소값은 clientHeight).
                && scrollWrap.scrollHeight > 0 && scrollWrap.scrollHeight <= getClientHeightByDom(scrollWrap)) {
                    _this4.triggerUpLoading();
                }
            }, options.up.loadFull.delay || 0);
        }
    }, {
        key: 'triggerDownLoading',
        value: function triggerDownLoading() {
            var options = this.options;

            if (!this.hooks[HOOK_BEFORE_DOWN_LOADING] || this.hooks[HOOK_BEFORE_DOWN_LOADING](this.downHight, options.down.offset)) {
                // 후크가 없거나 후크가 true를 반환합니다. 주로 비밀 정원과 유사한 사용자 지정 풀다운 새로 고침 애니메이션 구현을 용이하게하는 데 사용됩니다.
                this.downLoading = true;
                this.translateContentWrap(options.down.offset, options.down.bounceTime);

                this.events[EVENT_DOWN_LOADING] && this.events[EVENT_DOWN_LOADING]();
            }
        }
    }, {
        key: 'endDownLoading',
        value: function endDownLoading() {
            var options = this.options;

            if (this.downLoading) {
                // 로드 할 때 끝이 허용되어야합니다.
                this.translateContentWrap(0, options.down.bounceTime);
                this.downLoading = false;
            }
        }
    }, {
        key: 'triggerUpLoading',
        value: function triggerUpLoading() {
            this.upLoading = true;
            this.events[EVENT_UP_LOADING] && this.events[EVENT_UP_LOADING]();
        }

        /**
         * 풀업 로딩 애니메이션을 종료 할 때 완료되었는지 확인해야합니다 (더 이상로드 할 수 없음, 데이터 없음).
         * @param {Boolean} isFinishUp 是否结束上拉加载
         */

    }, {
        key: 'endUpLoading',
        value: function endUpLoading(isFinishUp) {
            if (this.upLoading) {
                this.upLoading = false;

                if (isFinishUp) {
                    this.isFinishUp = true;
                } else {
                    this._loadFull();
                }
            }
        }
    }, {
        key: 'resetUpLoading',
        value: function resetUpLoading() {
            if (this.isFinishUp) {
                this.isFinishUp = false;
            }

            // 전체 화면을로드해야하는지 확인
            this._loadFull();

            this.events[EVENT_RESET_UP_LOADING] && this.events[EVENT_RESET_UP_LOADING]();
        }

        /**
         * 지정된 y 위치로 스크롤
         * @param {Number} y top坐标
         * @param {Number} duration 单位毫秒
         */

    }, {
        key: 'scrollTo',
        value: function scrollTo(y, duration) {
            var _this5 = this;

            var scrollWrap = this.scrollWrap;
            var translateDuration = duration || 0;
            // 최대 스크롤 가능 y
            var maxY = scrollWrap.scrollHeight - getClientHeightByDom(scrollWrap);
            var translateY = y || 0;

            translateY = Math.max(translateY, 0);
            translateY = Math.min(translateY, maxY);

            // 차이 (음수 일 수 있음)
            var diff = scrollWrap.scrollTop - translateY;

            if (diff === 0 || translateDuration === 0) {
                scrollWrap.scrollTop = translateY;

                return;
            }

            // 초당 60 프레임, 총 프레임 수를 계산 한 다음 각 프레임의 단계 크기를 계산합니다.
            var count = Math.floor(translateDuration / PER_SECOND);
            var step = diff / count;
            var curr = 0;

            var execute = function execute() {
                if (curr < count) {
                    if (curr === count - 1) {
                        // 계산 오류를 방지하려면 마지막으로 y를 직접 설정하십시오.
                        scrollWrap.scrollTop = translateY;
                    } else {
                        scrollWrap.scrollTop -= step;
                    }
                    curr += 1;
                    requestAnimationFrame(execute);
                } else {
                    scrollWrap.scrollTop = translateY;
                    _this5.isScrollTo = false;
                }
            };

            // 잠긴 상태
            this.isScrollTo = true;
            requestAnimationFrame(execute);
        }

        /**
         * 풀다운 프로세스, 풀다운 새로 고침, 풀업로드, 슬라이딩 및 기타 이벤트를 포함한 모니터링 이벤트를 모니터링 할 수 있습니다.
         * @param {String} event 이벤트 이름, 선택적 이름
         * 상단의 상수가 정의됩니다
         * @param {Function} callback 콜백
         */

    }, {
        key: 'on',
        value: function on(event, callback) {
            if (event && typeof callback === 'function') {
                this.events[event] = callback;
            }
        }

        /**
         * 비밀의 정원에 들어가는 것과 같은 일부 사용자 지정 새로 고침 애니메이션에서 주로 사용되는 등록 후크 기능
         * @param {String} hook 이름, 범위는 다음과 같습니다.
         * beforeDownLoading downLoading 준비 여부, false를 반환하면 사용자 정의 애니메이션이 완전히로드되지 않고 입력됩니다.
         * @param {Function} callback 콜백
         */

    }, {
        key: 'hook',
        value: function hook(_hook, callback) {
            if (_hook && typeof callback === 'function') {
                this.hooks[_hook] = callback;
            }
        }
    }]);

    return Scroll;
}();

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

var defaultSetting = {
    // 다운
    down: {
        // 기본적으로 잠금이 없으며 API를 통해 동적으로 설정할 수 있습니다.
        isLock: false,
        // 자동으로 풀다운하여 새로 고침할지 여부
        isAuto: false,
        // isAuto = true가 설정된 경우 적용됩니다. 초기 풀다운 새로 고침 트리거 이벤트에서 애니메이션을 표시할지 여부입니다. false 인 경우 초기로드는 애니메이션이 아닌 콜백 만 트리거합니다.
        isAllowAutoLoading: true,
        // 풀다운 새로 고침을 어떤 상황에서든 트리거 할 수 있는지 여부, 거짓이면 풀다운을 풀다운 할 때 트리거되지 않습니다.
        isAways: false,
        // 스크롤을 아래로 당길 때 움직 일지 여부 (css3), 닫으면 커스텀 애니메이션을 구현할 수 있습니다.
        isScrollCssTranslate: true,
        // 풀다운 후 기본적으로 풀업을 재설정할지 여부
        isAutoResetUpLoading: true,
        // 길이보다 길게 당기고 새로 고침하려면 아래로 당깁니다.
        offset: 75,
        // 댐핑 계수, 풀다운이 오프셋보다 작을 때의 댐핑 계수 값이 0에 가까울수록 높이 변화가 작아지고 풀다운이 더 어려워집니다.
        dampRateBegin: 1,
        // 감쇠 계수, 풀다운 거리가 오프셋보다 클 때 풀다운 영역의 높이 비율을 변경합니다. 값이 0에 가까울수록 높이 변경이 작아지고 풀다운이 더 어려워집니다.
        dampRate: 0.3,
        // 리바운드 애니메이션 시간
        bounceTime: 300,
        successAnim: {
            // 풀다운 새로 고침이 완료된 후 애니메이션이 성공했는지 여부, 기본값은 false입니다. xxx 데이터를 성공적으로 새로 고치려면 true로 설정하고 해당 후크 기능을 구현하십시오.
            isEnable: false,
            duration: 300
        },
        // 풀다운되면 콜백이 제공되며 기본값은 null이며 실행되지 않습니다.
        onPull: null,
        // 취소시 콜백
        onCalcel: null,
        callback: noop
    },
    // 업
    up: {
        // 기본적으로 잠금이 없으며 API를 통해 동적으로 설정할 수 있습니다.
        isLock: false,
        // 자동 풀업 및로드 여부-자동 초기화 여부
        isAuto: true,
        // 기본적으로 풀업 진행률 표시 줄을 표시할지 여부는 API를 통해 변경할 수 있습니다.
        isShowUpLoading: true,
        // 바닥으로부터의 높이 (높이에 도달하면 트리거 됨)
        offset: 100,
        loadFull: {
            // 구성을 연 후 화면이 가득 차지 않는 한 자동으로로드됩니다.
            isEnable: true,
            delay: 300
        },
        // 스크롤 할 때 콜백이 제공되며 기본값은 null이며 실행되지 않습니다.
        onScroll: null,
        callback: noop
    },
    // 컨테이너
    container: '#minirefresh',
    // 수평 슬라이딩을 잠글 지 여부, 잠긴 경우 기본 스크롤 막대는 슬라이드 할 수 없습니다.
    isLockX: true,
    // 스크롤바 표시 여부
    isScrollBar: true,
    // minirefresh-scroll 개체의 스크롤 대신 본문 개체의 스크롤을 사용할지 여부
    // 페이지를 연 후 풀다운 새로 고침을 한 번만 할 수 있습니다. 그렇지 않으면 충돌이 발생합니다.
    isUseBodyScroll: false
};

var CLASS_HIDDEN_SCROLLBAR = 'minirefresh-hide-scrollbar';

var Core = function () {
    /**
     * 건설(빌드)
     * @param {Object} options 구성 정보
     * @constructor
     */
    function Core(options) {
        _classCallCheck(this, Core);

        osMixin(this);
        this.options = extend(true, {}, defaultSetting, options);

        this.container = selector(this.options.container);
        // 아래로 애니메이션 작업에 사용되는 스크롤의 dom-wrapper 아래의 첫 번째 노드
        this.contentWrap = this.container.children[0];
        // 기본값은 전체 컨테이너를 스크롤하는 것입니다.
        // 그러나 본문의 스크롤링과 호환되도록 두 개의 개체로 분할하여 쉽게 처리 할 수 ​​있습니다.
        // 본문이 사용되는 경우 scrollWrap은 항상 본문입니다.
        // 슬라이딩은 아래로 당길 때 번역을 의미하지 않고 (현재는 contentWrap) 기본 기본 슬라이딩 만 참조합니다.
        this.scrollWrap = this.options.isUseBodyScroll ? document.body : this.container;

        if (!this.options.isScrollBar) {
            this.container.classList.add(CLASS_HIDDEN_SCROLLBAR);
        }

        // 초기 후크
        this._initHook && this._initHook(this.options.down.isLock, this.options.up.isLock);

        // 내부적으로 슬라이딩 모니터링을 처리하는 Scroll 객체 생성
        this.scroller = new Scroll(this);

        // 내부 처리 스크롤
        this._initEvent();
        // 초기화 중에 잠긴 경우 잠금이 해제되지 않았을 때 잠금 해제를 방지하기 위해 잠금을 트리거해야합니다 (로직 버그가 트리거 됨).
        this.options.up.isLock && this._lockUpLoading(this.options.up.isLock);
        this.options.down.isLock && this._lockDownLoading(this.options.down.isLock);
    }

    _createClass(Core, [{
        key: '_initEvent',
        value: function _initEvent() {
            var _this = this;

            // 캐시 옵션, 구성의이 부분은 재설정 할 수 없습니다
            var options = this.options;

            this.scroller.on('initScroll', function () {
                _this._initScrollHook && _this._initScrollHook();
            });
            this.scroller.on('downLoading', function (isHideLoading) {
                !isHideLoading && _this._downLoaingHook && _this._downLoaingHook();
                options.down.callback && options.down.callback();
            });
            this.scroller.on('cancelLoading', function () {
                _this._cancelLoaingHook && _this._cancelLoaingHook();
                options.down.onCalcel && options.down.onCalcel();
            });
            this.scroller.on('pull', function (downHight, downOffset) {
                _this._pullHook && _this._pullHook(downHight, downOffset);
                options.down.onPull && options.down.onPull(downHight, downOffset);
            });
            this.scroller.on('upLoading', function () {
                _this._upLoaingHook && _this._upLoaingHook(_this.options.up.isShowUpLoading);
                options.up.callback && options.up.callback(_this.options.up.isShowUpLoading);
            });
            this.scroller.on('resetUpLoading', function () {
                _this._resetUpLoadingHook && _this._resetUpLoadingHook();
            });
            this.scroller.on('scroll', function (scrollTop) {
                _this._scrollHook && _this._scrollHook(scrollTop);
                options.up.onScroll && options.up.onScroll(scrollTop);
            });

            // 정상로드가 허용되는지 확인하고, false를 반환하면 사용자 지정 풀다운 새로 고침을 의미하며 일반적으로 직접 처리합니다.
            this.scroller.hook('beforeDownLoading', function (downHight, downOffset) {
                return !_this._beforeDownLoadingHook || _this._beforeDownLoadingHook(downHight, downOffset);
            });
        }

        /**
         * 내부 실행, 풀다운 새로 고침 종료
         * @param {Boolean} isSuccess 풀 리퀘스트 성공 여부
         * @param {String} successTips 성공 팁을 업데이트해야 함
         * 성공적인 애니메이션이 켜져있을 때 성공을위한 프롬프트는 종종 업데이트 10 뉴스와 같이 외부에서 동적으로 업데이트되어야합니다
         */

    }, {
        key: '_endDownLoading',
        value: function _endDownLoading(isSuccess, successTips) {
            var _this2 = this;

            if (!this.options.down) {
                //전달 실패로 인한 오류 방지
                return;
            }

            if (this.scroller.downLoading) {
                // 해당 후크는로드 할 때만 실행되어야합니다.
                var successAnim = this.options.down.successAnim.isEnable;
                var successAnimTime = this.options.down.successAnim.duration;

                if (successAnim) {
                    // 성공적인 애니메이션이있는 경우
                    this._downLoaingSuccessHook && this._downLoaingSuccessHook(isSuccess, successTips);
                } else {
                    // 기본값은 성공적인 애니메이션 없음입니다.
                    successAnimTime = 0;
                }

                setTimeout(function () {
                    // 성공적인 애니메이션이 끝난 후 위치를 재설정 할 수 있습니다.
                    _this2.scroller.endDownLoading();
                    // 트리거 엔드 후크
                    _this2._downLoaingEndHook && _this2._downLoaingEndHook(isSuccess);
                }, successAnimTime);
            }
        }

        /**
         * 잠금 풀업 로딩
         * 활성화 및 비활성화를 하나의 잠금 API로 결합
         * @param {Boolean} isLock 
         */

    }, {
        key: '_lockUpLoading',
        value: function _lockUpLoading(isLock) {
            this.options.up.isLock = isLock;
            this._lockUpLoadingHook && this._lockUpLoadingHook(isLock);
        }

        /**
         * 풀다운 새로 고침 잠금
         * @param {Boolean} isLock 
         */

    }, {
        key: '_lockDownLoading',
        value: function _lockDownLoading(isLock) {
            this.options.down.isLock = isLock;
            this._lockDownLoadingHook && this._lockDownLoadingHook(isLock);
        }

        /**
         * minirefresh 구성을 새로 고치십시오. 컨테이너, 콜백 등과 같은 키 구성을 업데이트하지 마십시오.
         * @param {Object} options 새 구성이 원본을 덮어 씁니다.
         */

    }, {
        key: 'refreshOptions',
        value: function refreshOptions(options) {
            this.options = extend(true, {}, this.options, options);
            this.scroller.refreshOptions(this.options);
            this._lockUpLoading(this.options.up.isLock);
            this._lockDownLoading(this.options.down.isLock);
            this._refreshHook && this._refreshHook();
        }

        /**
         * 당겨서 새로 고침
         * @param {Boolean} isSuccess 요청 성공 여부에 따라이 상태는 해당 주제로 전송됩니다.
         * @param {String} successTips 성공 팁을 업데이트해야 함
         * 성공적인 애니메이션이 켜져있을 때 성공을위한 프롬프트는 종종 업데이트 10 뉴스와 같이 외부에서 동적으로 업데이트되어야합니다.
         */

    }, {
        key: 'endDownLoading',
        value: function endDownLoading() {
            var isSuccess = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : true;
            var successTips = arguments[1];

            this._endDownLoading(isSuccess, successTips);
            // 동시에 풀업 로딩 상태가 복원됩니다. 이때 isShowUpLoading은 전달되지 않으므로이 값은 적용되지 않습니다.
            if (this.options.down.isAutoResetUpLoading) {
                this.resetUpLoading();
            }
        }

        /**
         * 풀업 로딩 상태를 재설정하고, 데이터가 더 이상 없을 경우 풀업 로딩을 계속할 수있게됩니다.
         */

    }, {
        key: 'resetUpLoading',
        value: function resetUpLoading() {
            this.scroller.resetUpLoading();
        }

        /**
         * 풀업 로딩 종료
         * @param {Boolean} isFinishUp 풀업 로딩 종료 여부, 종료되면 더 이상 데이터가 없으며 풀업 로딩을 더 이상 시작할 수 없음을 의미합니다.
         * 종료 후 다시 열려면 재설정해야합니다.
         */

    }, {
        key: 'endUpLoading',
        value: function endUpLoading(isFinishUp) {
            if (this.scroller.upLoading) {
                this.scroller.endUpLoading(isFinishUp);
                this._upLoaingEndHook && this._upLoaingEndHook(isFinishUp);
            }
        }
    }, {
        key: 'triggerUpLoading',
        value: function triggerUpLoading() {
            this.scroller.triggerUpLoading();
        }
    }, {
        key: 'triggerDownLoading',
        value: function triggerDownLoading() {
            this.scroller.scrollTo(0);
            this.scroller.triggerDownLoading();
        }

        /**
         * 지정된 y 위치로 스크롤
         * @param {Number} y 스와이프할 최고 값
         * @param {Number} duration 밀리초 단위
         */

    }, {
        key: 'scrollTo',
        value: function scrollTo(y, duration) {
            this.scroller.scrollTo(y, duration);
        }

        /**
         * 현재 스크롤 위치 가져 오기
         * @return {Number} 현재 스크롤 위치를 반환합니다.
         */

    }, {
        key: 'getPosition',
        value: function getPosition() {
            return this.scrollWrap.scrollTop;
        }
    }]);

    return Core;
}();

var MiniRefreshTools$2 = {};

Object.keys(lang).forEach(function (name) {
    MiniRefreshTools$2[name] = lang[name];
});

// 네임 스페이스의 특수 바인딩
MiniRefreshTools$2.namespace = function (namespaceStr, target) {
    namespace(MiniRefreshTools$2, namespaceStr, target);
};

MiniRefreshTools$2.Core = Core;
MiniRefreshTools$2.version = '2.0.0';

// 테마와 코어를 함께 방지하고 require 모드에서 전역 변수가 불가능한 상황
window.MiniRefreshTools = MiniRefreshTools$2;

var _createClass$2 = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck$2(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var Core$2 = MiniRefreshTools.Core;
var version = MiniRefreshTools.version;
var extend$1 = MiniRefreshTools.extend;
var namespace$1 = MiniRefreshTools.namespace;

/**
 * 기본적으로 제공되는 일부 CSS 클래스는 일반적으로 변경되지 않습니다 (프레임 워크에서 제공).
 * 테마 필드는 테마에 따라 다른 값을 갖습니다.
 * 본문 스크롤 사용시 CLASS_BODY_SCROLL_WRAP 스타일 추가 필요
 */
var CLASS_THEME = 'minirefresh-theme-default';
var CLASS_DOWN_WRAP = 'minirefresh-downwrap';
var CLASS_UP_WRAP = 'minirefresh-upwrap';
var CLASS_FADE_IN = 'minirefresh-fade-in';
var CLASS_FADE_OUT = 'minirefresh-fade-out';
var CLASS_TO_TOP = 'minirefresh-totop';
var CLASS_ROTATE = 'minirefresh-rotate';
var CLASS_HARDWARE_SPEEDUP = 'minirefresh-hardware-speedup';
var CLASS_HIDDEN = 'minirefresh-hidden';
var CLASS_BODY_SCROLL_WRAP = 'body-scroll-wrap';

/**
 * 本主题的特色样式
 */
var CLASS_DOWN_SUCCESS = 'downwrap-success';
var CLASS_DOWN_ERROR = 'downwrap-error';
var CLASS_STATUS_DEFAULT = 'status-default';
var CLASS_STATUS_PULL = 'status-pull';
var CLASS_STATUS_LOADING = 'status-loading';
var CLASS_STATUS_SUCCESS = 'status-success';
var CLASS_STATUS_ERROR = 'status-error';
var CLASS_STATUS_NOMORE = 'status-nomore';

/**
 * 一些常量
 */
var DEFAULT_DOWN_HEIGHT = 75;

var defaultSetting$1 = {
    down: {
        successAnim: {
            //풀다운 새로 고침이 완료된 후 애니메이션이 성공했는지 여부, 기본값은 false입니다. xxx 데이터를 성공적으로 새로 고치려면 true로 설정하고 해당 후크 기능을 구현하십시오.
            isEnable: false,
            duration: 300
        },
        // 선택 사항, 풀다운 새로 고침 가능 상태에서 풀다운하여 컨트롤에 표시된 제목 콘텐츠를 새로 고칩니다.
        contentdown: '', // 아래로 당겨 새로고침
        // 선택 사항, 새로 고침 가능 상태를 해제 할 때 풀다운하여 컨트롤에 표시된 제목 콘텐츠를 새로 고침합니다.
        contentover: '', //릴리스 새로고침
        // 선택 사항, 상태를 새로 고칠 때 풀다운하여 컨트롤에 표시된 제목 콘텐츠를 새로 고칩니다.
        contentrefresh: '', //로드중...
        // 선택 사항, 성공적인 새로 고침 프롬프트, successAnim이 활성화 된 경우에만 유효 함
        contentsuccess: '', //성공적으로 새로 고침
        // 선택 사항, 새로 고침 실패 알림, 오류 콜백, successAnim이 활성화 된 경우에만 유효
        contenterror: '', //새로고침 실패..
        // 기본적으로 CSS 애니메이션을 따를 지 여부
        isWrapCssTranslate: false
    },
    up: {
        toTop: {
            // 열기 여부 클릭 맨 위로 돌아 가기
            isEnable: true,
            duration: 300,
            // 스크롤하여 표시 할 거리
            offset: 800
        },
        // 기본값은 비어 있으며 직접 변경할 수 있습니다. 더 많이 보려면 위로 당기세요.
        contentdown: '',
        contentrefresh: '',//로딩중...
        contentnomore: '모든 내역이 조회되었습니다.'
    }
};

var MiniRefreshTheme = function (_Core) {
    _inherits(MiniRefreshTheme, _Core);

    /**
     * 새 기본 매개 변수를 사용하는 구성
     * @param {Object} options 配置信息
     * @constructor
     */
    function MiniRefreshTheme(options) {
        _classCallCheck$2(this, MiniRefreshTheme);

        var newOptions = extend$1(true, {}, defaultSetting$1, options);

        return _possibleConstructorReturn(this, (MiniRefreshTheme.__proto__ || Object.getPrototypeOf(MiniRefreshTheme)).call(this, newOptions));
    }

    _createClass$2(MiniRefreshTheme, [{
        key: '_initHook',
        value: function _initHook() {
            var container = this.container;
            var contentWrap = this.contentWrap;

            container.classList.add(CLASS_THEME);
            // 애니메이션을 더 부드럽게 만드는 하드웨어 가속
            contentWrap.classList.add(CLASS_HARDWARE_SPEEDUP);

            if (this.options.isUseBodyScroll) {
                // 본문 스크롤을 사용하는 경우 해당 스타일을 추가해야합니다. 그렇지 않으면 기본 절대 값을 모니터링 할 수 없습니다.
                container.classList.add(CLASS_BODY_SCROLL_WRAP);
                contentWrap.classList.add(CLASS_BODY_SCROLL_WRAP);
            }

            this._initDownWrap();
            this._initUpWrap();
            this._initToTop();
        }

        /**
         * 새로 고침을 구현하려면 새 구성에 따라 약간의 변경이 필요합니다.
         */

    }, {
        key: '_refreshHook',
        value: function _refreshHook() {
            // csstranslate를 전환하는 경우 호환되어야합니다.
            if (this.options.down.isWrapCssTranslate) {
                this._transformDownWrap(-this.downWrapHeight);
            } else {
                this._transformDownWrap(0, 0, true);
            }

            // toTop의 개발 컨트롤이 표시되면 숨겨 지도록 업데이트되며 즉시 숨겨져 야합니다.
            if (!this.options.up.toTop.isEnable) {
                this.toTopBtn && this.toTopBtn.classList.add(CLASS_HIDDEN);
                this.isShowToTopBtn = false;
            }
        }
    }, {
        key: '_initDownWrap',
        value: function _initDownWrap() {
            var container = this.container;
            var contentWrap = this.contentWrap;
            var options = this.options;

            // 드롭 다운 영역
            var downWrap = document.createElement('div');

            downWrap.className = CLASS_DOWN_WRAP + ' ' + CLASS_HARDWARE_SPEEDUP;
            downWrap.innerHTML = ' \n            <div class="downwrap-content">\n                <p class="downwrap-progress"></p>\n                <p class="downwrap-tips">' + options.down.contentdown + '</p>\n            </div>\n        ';
            container.insertBefore(downWrap, contentWrap);

            this.downWrap = downWrap;
            this.downWrapProgress = this.downWrap.querySelector('.downwrap-progress');
            this.downWrapTips = this.downWrap.querySelector('.downwrap-tips');
            // 풀 중 상태 전환을 제어하기 위해 변수를 풀다운 할 수 있는지 여부
            this.isCanPullDown = false;
            this.downWrapHeight = downWrap.offsetHeight || DEFAULT_DOWN_HEIGHT;
            this._transformDownWrap(-this.downWrapHeight);
            MiniRefreshTheme._changeWrapStatusClass(this.downWrap, CLASS_STATUS_DEFAULT);
        }
    }, {
        key: '_transformDownWrap',
        value: function _transformDownWrap() {
            var offset = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : 0;
            var duration = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 0;
            var isForce = arguments[2];

            if (!isForce && !this.options.down.isWrapCssTranslate) {
                // isWrapCssTranslate가 꺼져 있어도 isForce 매개 변수를 통해 강제로 이동할 수 있습니다.
                return;
            }

            var duratuinStr = duration + 'ms';
            var transformStr = 'translateY(' + offset + 'px)  translateZ(0px)';

            // 애니메이션 중 translateZ를 기억하십시오. 그렇지 않으면 하드웨어 가속을 덮어 씁니다.
            this.downWrap.style.webkitTransitionDuration = duratuinStr;
            this.downWrap.style.transitionDuration = duratuinStr;
            this.downWrap.style.webkitTransform = transformStr;
            this.downWrap.style.transform = transformStr;
        }
    }, {
        key: '_initUpWrap',
        value: function _initUpWrap() {
            var contentWrap = this.contentWrap;
            var options = this.options;

            // 영역을 당겨
            var upWrap = document.createElement('div');

            upWrap.className = CLASS_UP_WRAP + ' ' + CLASS_HARDWARE_SPEEDUP;
            upWrap.innerHTML = ' \n            <p class="upwrap-progress"></p>\n            <p class="upwrap-tips">' + options.up.contentdown + '</p>\n        ';

            upWrap.style.visibility = 'hidden';
            // 컨테이너에 추가
            contentWrap.appendChild(upWrap);

            this.upWrap = upWrap;
            this.upWrapProgress = this.upWrap.querySelector('.upwrap-progress');
            this.upWrapTips = this.upWrap.querySelector('.upwrap-tips');
            MiniRefreshTheme._changeWrapStatusClass(this.upWrap, CLASS_STATUS_DEFAULT);
        }

        /**
         * 사용자 정의 구현 toTop, 이것은 추가 이벤트이므로 코어에 추가되지 않지만 구현 여부 또는 달성 할 내용을 결정하는 것은 각 테마에 달려 있습니다.
         * 그러나 기본 minirefresh-totop 스타일은 쉽게 사용할 수 있도록 프레임 워크에서 계속 제공됩니다.
         */

    }, {
        key: '_initToTop',
        value: function _initToTop() {
            var _this2 = this;

            var options = this.options;
            var toTop = options.up.toTop.isEnable;
            var duration = options.up.toTop.duration;

            if (toTop) {
                var toTopBtn = document.createElement('div');

                toTopBtn.className = CLASS_TO_TOP + ' ' + CLASS_THEME;

                toTopBtn.onclick = function () {
                    _this2.scroller.scrollTo(0, duration);
                };
                toTopBtn.classList.add(CLASS_HIDDEN);
                this.toTopBtn = toTopBtn;
                this.isShowToTopBtn = false;
             	// 충돌을 방지하기 위해 기본적으로 본문에 추가
                // 컨테이너에 추가해야합니다. 그렇지 않으면 여러 토탑이 인식되지 않습니다.
                this.container.appendChild(toTopBtn);
            }
        }
    }, {
        key: '_pullHook',
        value: function _pullHook(downHight, downOffset) {
            var options = this.options;
            var FULL_DEGREE = 360;

            if (downHight < downOffset) {
                if (this.isCanPullDown) {
                    this.isCanPullDown = false;
                    MiniRefreshTheme._changeWrapStatusClass(this.downWrap, CLASS_STATUS_DEFAULT);
                    this.downWrapTips.innerText = options.down.contentdown;
                }
            } else if (!this.isCanPullDown) {
                this.downWrapTips.innerText = options.down.contentover;
                this.isCanPullDown = true;
                MiniRefreshTheme._changeWrapStatusClass(this.downWrap, CLASS_STATUS_PULL);
            }

            if (this.downWrapProgress) {
                var rate = downHight / downOffset;
                var progress = FULL_DEGREE * rate;
                var rotateStr = 'rotate(' + progress + 'deg)';

                this.downWrapProgress.style.webkitTransform = rotateStr;
                this.downWrapProgress.style.transform = rotateStr;
            }

            this._transformDownWrap(-this.downWrapHeight + downHight);
        }
    }, {
        key: '_scrollHook',
        value: function _scrollHook(scrollTop) {
            //toTop을 판단하는데 사용
            var options = this.options;
            var toTop = options.up.toTop.isEnable;
            var toTopBtn = this.toTopBtn;

            if (toTop && toTopBtn) {
                if (scrollTop >= options.up.toTop.offset) {
                    if (!this.isShowToTopBtn) {
                        toTopBtn.classList.remove(CLASS_FADE_OUT);
                        toTopBtn.classList.remove(CLASS_HIDDEN);
                        toTopBtn.classList.add(CLASS_FADE_IN);
                        this.isShowToTopBtn = true;
                    }
                } else if (this.isShowToTopBtn) {
                    toTopBtn.classList.add(CLASS_FADE_OUT);
                    toTopBtn.classList.remove(CLASS_FADE_IN);
                    this.isShowToTopBtn = false;
                }
            }
        }
    }, {
        key: '_downLoaingHook',
        value: function _downLoaingHook() {
            //기본적으로 contentWrap과 동기화
            this._transformDownWrap(-this.downWrapHeight + this.options.down.offset, this.options.down.bounceTime);
            this.downWrapTips.innerText = this.options.down.contentrefresh;
            this.downWrapProgress.classList.add(CLASS_ROTATE);
            MiniRefreshTheme._changeWrapStatusClass(this.downWrap, CLASS_STATUS_LOADING);
        }
    }, {
        key: '_downLoaingSuccessHook',
        value: function _downLoaingSuccessHook(isSuccess, successTips) {
            this.options.down.contentsuccess = successTips || this.options.down.contentsuccess;
            this.downWrapTips.innerText = isSuccess ? this.options.down.contentsuccess : this.options.down.contenterror;
            this.downWrapProgress.classList.remove(CLASS_ROTATE);
            this.downWrapProgress.classList.add(CLASS_FADE_OUT);
            this.downWrapProgress.classList.add(isSuccess ? CLASS_DOWN_SUCCESS : CLASS_DOWN_ERROR);

            MiniRefreshTheme._changeWrapStatusClass(this.downWrap, isSuccess ? CLASS_STATUS_SUCCESS : CLASS_STATUS_ERROR);
        }
    }, {
        key: '_downLoaingEndHook',
        value: function _downLoaingEndHook(isSuccess) {
            this.downWrapTips.innerText = this.options.down.contentdown;
            this.downWrapProgress.classList.remove(CLASS_ROTATE);
            this.downWrapProgress.classList.remove(CLASS_FADE_OUT);
            this.downWrapProgress.classList.remove(isSuccess ? CLASS_DOWN_SUCCESS : CLASS_DOWN_ERROR);
            // 기본값은 보이지 않습니다.
            // 다시 재설정해야 함
            this.isCanPullDown = false;
            this._transformDownWrap(-this.downWrapHeight, this.options.down.bounceTime);
            MiniRefreshTheme._changeWrapStatusClass(this.downWrap, CLASS_STATUS_DEFAULT);
        }
    }, {
        key: '_cancelLoaingHook',
        value: function _cancelLoaingHook() {
            this._transformDownWrap(-this.downWrapHeight, this.options.down.bounceTime);
            MiniRefreshTheme._changeWrapStatusClass(this.downWrap, CLASS_STATUS_DEFAULT);
        }
    }, {
        key: '_upLoaingHook',
        value: function _upLoaingHook(isShowUpLoading) {
            if (isShowUpLoading) {
                this.upWrapTips.innerText = this.options.up.contentrefresh;
                this.upWrapProgress.classList.add(CLASS_ROTATE);
                this.upWrapProgress.classList.remove(CLASS_HIDDEN);
                this.upWrap.style.visibility = 'visible';
            } else {
                this.upWrap.style.visibility = 'hidden';
            }
            MiniRefreshTheme._changeWrapStatusClass(this.upWrap, CLASS_STATUS_LOADING);
        }
    }, {
        key: '_upLoaingEndHook',
        value: function _upLoaingEndHook(isFinishUp) {
            if (!isFinishUp) {
                // 다음에 더로드 할 수 있습니다.
                // this.upWrap.style.visibility = 'hidden';
                this.upWrapTips.innerText = this.options.up.contentdown;
                MiniRefreshTheme._changeWrapStatusClass(this.upWrap, CLASS_STATUS_DEFAULT);
            } else {
                // 더 이상 데이터 없음
                // this.upWrap.style.visibility = 'visible';
                this.upWrapTips.innerText = this.options.up.contentnomore;
                MiniRefreshTheme._changeWrapStatusClass(this.upWrap, CLASS_STATUS_NOMORE);
            }
            this.upWrapProgress.classList.remove(CLASS_ROTATE);
            this.upWrapProgress.classList.add(CLASS_HIDDEN);
        }
    }, {
        key: '_resetUpLoadingHook',
        value: function _resetUpLoadingHook() {
            // this.upWrap.style.visibility = 'hidden';
            this.upWrapTips.innerText = this.options.up.contentdown;
            this.upWrapProgress.classList.remove(CLASS_ROTATE);
            this.upWrapProgress.classList.add(CLASS_HIDDEN);
            MiniRefreshTheme._changeWrapStatusClass(this.upWrap, CLASS_STATUS_DEFAULT);
        }
    }, {
        key: '_lockUpLoadingHook',
        value: function _lockUpLoadingHook(isLock) {
            this.upWrap.style.visibility = isLock ? 'hidden' : 'visible';
        }
    }, {
        key: '_lockDownLoadingHook',
        value: function _lockDownLoadingHook(isLock) {
            this.downWrap.style.visibility = isLock ? 'hidden' : 'visible';
        }
    }], [{
        key: '_changeWrapStatusClass',
        value: function _changeWrapStatusClass(wrap, statusClass) {
            wrap.classList.remove(CLASS_STATUS_NOMORE);
            wrap.classList.remove(CLASS_STATUS_DEFAULT);
            wrap.classList.remove(CLASS_STATUS_PULL);
            wrap.classList.remove(CLASS_STATUS_LOADING);
            wrap.classList.remove(CLASS_STATUS_SUCCESS);
            wrap.classList.remove(CLASS_STATUS_ERROR);
            wrap.classList.add(statusClass);
        }
    }]);

    return MiniRefreshTheme;
}(Core$2);

MiniRefreshTheme.sign = 'default';
MiniRefreshTheme.version = version;
namespace$1('theme.defaults', MiniRefreshTheme);

// 전역 변수 덮어 쓰기
window.MiniRefresh = MiniRefreshTheme;

/**
 * MiniRefreshTools 변수는 기본적으로 노출되며 모든 주요 테마가 여기에 연결됩니다.
 */

return MiniRefreshTools$2;

})));
