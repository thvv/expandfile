/** dhtml-lightbox.js - lightbox DHTML picture display
 *  thanks to Jason Cranford Teague for his example in CSS DHTML & AJAX, 4th edition
 *
 *  02/09/13 THVV derived from dhtmlgallery.js
 *
 **/
var objectPhotoSlide; // ptr to DOM 'photoSlide'
var objectSlide; //ptr to DOM 'slide'

// expects the following
    // <div id="cover" onClick="hideLightBox()">&nbsp;</div>
    // <div id="slide">
    //   ... optional logo bar ...
    //   <span class="slideControl" onclick="hideLightBox()">Close &otimes;</span>
    //   <div id="photoSlide">Loading</div>
    // </div>

function findLivePageWidth() {
    if (window.innerWidth)
	return window.innerWidth;
    if (document.body.clientWidth)
	return document.body.clientWidth;
    return (null);
} // findLivePageWidth

function showLightBox(bvfilename, bvwidth, bvheight, bvalt, bvtitle, bvcaption) {
    var hh = '<img src="' + bvfilename + '" width="' + bvwidth + '" height="' + bvheight +
	'" border="0" title="'+bvtitle+'" alt="'+bvalt+'" onClick="hideLightBox()" />';
    hh += '<p class="capt">' + bvcaption +'</p>';
    objectPhotoSlide = document.getElementById('photoSlide');
    // alert('ops='+objectPhotoSlide+' => '+hh);
    objectPhotoSlide.innerHTML = hh;
    objectPhotoSlide.style['width'] = bvwidth+"px"; // in case the text is wider than the picture
    window.scrollTo(0,0); // problem: any time you pop a picture the underlying page jumps to the top.  if you don't do this, you have to scroll the popup.
    livePageWidth = findLivePageWidth();
    newLeft = ((livePageWidth/2)-8) - (bvwidth/2);
    objectSlide = document.getElementById('slide');
    objectSlide.style.left = newLeft + 'px';
    objectSlide.style.display = 'block';
    objectCover = document.getElementById('cover');
    objectCover.style.display = 'block';
} // showLightBox

// function invoked if we have a regular picture and a bigsize picture, in any case shown in the bvwidth x bvheight CSS dimensions
function showLightBox2(bvfilename, bvwidth, bvheight, bvalt, bvtitle, bvcaption, bvfilename2x) {
    var hh = '<img src="' + bvfilename + '" width="' + bvwidth + '" height="' + bvheight +
	'" border="0" title="'+bvtitle+'" alt="'+bvalt+'" onClick="hideLightBox()" srcset="'+bvfilename+' 1x, '+bvfilename2x+' 2x" />';
    hh += '<p class="capt">' + bvcaption +'</p>';
    objectPhotoSlide = document.getElementById('photoSlide');
    // alert('ops='+objectPhotoSlide+' => '+hh);
    objectPhotoSlide.innerHTML = hh;
    objectPhotoSlide.style['width'] = bvwidth+"px"; // in case the text is wider than the picture
    window.scrollTo(0,0); // problem: any time you pop a picture the underlying page jumps to the top.  if you don't do this, you have to scroll the popup.
    livePageWidth = findLivePageWidth();
    newLeft = ((livePageWidth/2)-8) - (bvwidth/2);
    objectSlide = document.getElementById('slide');
    objectSlide.style.left = newLeft + 'px';
    objectSlide.style.display = 'block';
    objectCover = document.getElementById('cover');
    objectCover.style.display = 'block';
} // showLightBox2

function hideLightBox() {
    objectSlide=document.getElementById('slide');
    objectCover=document.getElementById('cover');
    objectSlide.style.display = 'none'; 
    objectCover.style.display = 'none';
} // hideLightBox
