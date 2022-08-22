({
    doInit : function(component,event,helper){
        let action = component.get ('c.getVideoLinks');
        let videos = [];

        action.setCallback (this, function (response) {
            let state = response.getState ();
            if (state === 'SUCCESS') {
                let result = response.getReturnValue ();
                console.log('result',result.length);
                var counter = 1;
                for(var key in result){
                    /*if(counter == 1){
                        helper.generateURL(component,result[key].Video_URL__c);
                    }*/
                    var eachVideo = {};
                    eachVideo.Caption = result[key].Name;
                    eachVideo.VideoURL = result[key].Video_URL__c;
                    eachVideo.URL = helper.generateURL(component,result[key].Video_URL__c);
                    eachVideo.ImageName = result[key].Image_Name__c;
                    eachVideo.ImageURL = $A.get('$Resource.Video_Images')+'/VideoImages/'+eachVideo.ImageName+'.png';
                    console.log('eachVideo.ImageURL',eachVideo.ImageURL);
                    eachVideo.Order = counter;
                    videos.push(eachVideo);
                    counter++;
                }
                component.set("v.selectedVideo",videos[0]);
                helper.sendToVF(component,videos[0].URL);
                component.set("v.totalVideos",videos.length);
                component.set("v.allVideos",videos);
                var width = 100/videos.length;
                console.log('width',width);
                component.set("v.width",width);
                document.getElementById("Video-1").className = document.getElementById("Video-1").className + " active";
            } else if (state === 'INCOMPLETE'){
                console.log ('Exception in reteiving Data :' );
            } else if (state === 'ERROR'){
                console.log ('Exception in reteiving Data :' + response.getError ());
            }
            
        });
        $A.enqueueAction (action);         
    },
    currentSlide : function(component,event,helper) {
        var targetID =  event.target.id;
        console.log('targetID',targetID);
        var currentSlide = targetID.split("Video-")[1];
        var videos = component.get("v.allVideos");
        var videosString = JSON.stringify(videos);
        videos = JSON.parse(videosString);
        var selectedVideo = videos[currentSlide-1];
        var totalVideos = component.get("v.totalVideos");
        console.log('totalVideos',totalVideos);
        console.log('selectedVideo',selectedVideo);
        component.set("v.selectedVideo",selectedVideo);
        helper.sendToVF(component,selectedVideo.VideoURL);

        document.getElementById(targetID).className = document.getElementById(targetID).className + " active";
        for(var i=1;i<=totalVideos;i++){
            var element = 'Video-'+i;
            console.log('element',element);
            if(element != targetID){
                console.log('inside');
                document.getElementById(element).className = "demo cursor index";
            }
        }
        
    },
    plusSlides: function(component,event,helper){
        var currentslide = component.get('v.selectedVideo').Order;
        console.log('currentslide',currentslide);

    },
    minusSlides: function(component,event,helper){
        var currentslide = component.get('v.selectedVideo').Order;
        console.log('currentslide',currentslide);
    },
})