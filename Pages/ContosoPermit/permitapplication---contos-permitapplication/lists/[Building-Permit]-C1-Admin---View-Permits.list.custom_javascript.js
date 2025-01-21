$(document).ready(function (){
   $(".entitylist.entity-grid").on("loaded", function () {
      $(this).children(".view-grid").find("td[data-attribute='bp_permitstatus']").each(function (i, e){
         var value = $(this).data(value);
         $(this).css({
           "display": "flex"
         });
         // now that you have the value you can do something to the value
        switch(value.value.Value) {
          case 121260000:
            $(this).html("<span class='table-status-cell submitted'>Submitted</span>")
            break;
          case 121260003:
            $(this).html("<span class='table-status-cell review'>Under Review</span>");
            break;
          case 121260002:
            $(this).html("<span class='table-status-cell denied'>Denied</span>")
            break;
          case 121260001:
            $(this).html("<span class='table-status-cell approved'>Approved</span>")
            break;
          default:
            $(this).css({
              "color": "#000000"
            });
         }
      });
   });
});


const updateFormId = document.getElementById("update_form_id").value  
const viewFormId = document.getElementById("view_form_id").value  
const waitForElement = (selector) => {
  return new Promise((resolve) => {
    if(document.querySelector(selector)) {
      return resolve(document.querySelectorAll(selector))
    }
    const observer = new MutationObserver(() => {
      if(document.querySelector(selector)) {
        resolve(document.querySelectorAll(selector))
        observer.disconnect()
      } 
    })

    observer.observe(document.querySelector("div.entity-grid.entitylist"), {
      childList: true,
      subtree: true
    })
  })
}

waitForElement("a.edit-link.launch-modal").then((links) => {
  links.forEach((link) => {
    if(link.innerHTML.indexOf("View") < 0) {
      link.setAttribute("data-entityformid",updateFormId)
    }
    else {
      link.setAttribute("data-entityformid",viewFormId)
    }
  });
})