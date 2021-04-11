package {
    import flash.display.MovieClip;
    import flash.display.Stage;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.display.StageQuality;
    import flash.events.Event;
    import flash.events.NativeWindowBoundsEvent;
    import flash.geom.Point;

    public class Global extends MovieClip{
        static private var pp:PopupPanel;
        static public var stage:Stage;
        static public var chartArr:Array;
        static public var showChartArr:Array

        public function Global(){
            Global.stage = stage;           
            stage.align = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.quality = StageQuality.BEST;
            stage.addEventListener(Event.RESIZE, stageResizeHandler);
            stage.nativeWindow.title = "级别0 第一课 讲稿";
            stage.nativeWindow.minSize = new Point(1280, 720);
            getConfig();
            updateShowChartArr();
        }

        static public function alert(str:String, okFun:Function=null):void{
            pp = new PopupPanel();
            stage.addChild(pp);
            var panel = new AlertPanel();
            panel.setData(str);
            pp.init(panel, okFun, -1, -1, true, 0.2, null);
        }

        static public function popup(inst:MovieClip, okFun:Function=null, x:int=-1, y:int=-1, mode:Boolean=true, modeAlpha:Number=0.2, cancelFun:Function=null):void{
            pp = new PopupPanel();
            stage.addChild(pp);
            pp.init(inst, okFun, x, y, mode, modeAlpha, cancelFun);
        }
        static public function removePopup():void{
            pp.parent.removeChild(pp);
            pp = null;
        }

        static public function updateShowChartArr():void{
            showChartArr = [];
            var arr:Array = chartArr;
            for(var i:int=0; i<arr.length; i++){
                if(arr[i].visible == true) showChartArr.push(arr[i]);
            }
        }

        static public function getJsonConfig():Array{
            var charts:Array = [];
            var chart:Object;
            var arr:Array = chartArr;
            for(var i:int=0; i<arr.length; i++){
                chart = {};
                for(var nm:String in arr[i]){
                    if(nm != "inst"){
                        if(nm == "pages"){
                            var pages:Array = arr[i][nm];
                            var page:Object;
                            chart[nm] = [];
                            for(var j:int=0; j<pages.length; j++){
                                page = {};
                                for(var mm:String in pages[j]){
                                    if(mm != "inst") page[mm] = pages[j][mm];
                                }
                                chart[nm].push(page);
                            }
                        }else{
                            chart[nm] = arr[i][nm];
                        }
                    } 
                }
                charts.push(chart);
            }
            return charts;
        }
        static public function traceConfig():void{
            trace(JSON.stringify(getJsonConfig(), null, 2));
        }

        static public function getChartObj():Object{
            return {
                visible:true,
                label:"一网统管"+(chartArr.length+1),
                pages:[]
            }
        }

        static public function getPageObj():Object{
            return {label:"综合网格", uri:""};
        }

        static public function getConfig():void{
            var obj:Object = {
                thumb:"",
                charts:[
                    {
                        visible:true,
                        label:"第一节 概要",
                        pages:[
                            {label:"综合网格", uri:"file:///D:/course/course/level0/page0"},
                            {label:"事项词典", uri:"file:///D:/course/course/level0/page1"},
                            {label:"事项协同", uri:"file:///D:/course/course/level0/page2"}
                        ]
                    },
                    {
                        visible:true,
                        label:"第二节 苹果树",
                        pages:[
                            {label:"综合网格", uri:""},
                            {label:"事项词典", uri:""},
                            {label:"事项协同", uri:""}
                        ]
                    },
                    {
                        visible:false,
                        label:"第三节 小猴",
                        pages:[
                            {label:"综合网格", uri:""},
                            {label:"事项词典", uri:""},
                            {label:"事项协同", uri:""}
                        ]
                    },
                    {
                        visible:true,
                        label:"第四节 摘苹果",
                        pages:[
                            {label:"综合网格", uri:""},
                            {label:"事项词典", uri:""},
                            {label:"事项协同", uri:""}
                        ]
                    },
                    {
                        visible:true,
                        label:"第五小节 儿歌",
                        pages:[
                            {label:"综合网格", uri:""},
                            {label:"事项词典", uri:""},
                            {label:"事项协同", uri:""}
                        ]
                    },
                    {
                        visible:true,
                        label:"第六小节 听和说",
                        pages:[
                            {label:"综合网格", uri:""},
                            {label:"事项词典", uri:""},
                            {label:"事项协同", uri:""}
                        ]
                    }
                ]
            }
            chartArr = obj.charts;
        }

        private function stageResizeHandler(e:Event):void{
            if(pp) pp.resize();
            if(tabBar) tabBar.resize();
            if(pageBar) pageBar.resize();
            if(pageBarBg) pageBarBg.width = stage.stageWidth;
            if(login) login.x = stage.stageWidth-95;
            if(subject) subject.resize();
            if(html) html.resize();
        }
    }
}