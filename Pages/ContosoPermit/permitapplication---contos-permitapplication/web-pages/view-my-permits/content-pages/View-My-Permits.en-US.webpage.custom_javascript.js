$(document).ready(function (){
    $('#entitylist-filters').prepend('<div class="filter-group"></div>');
    $('.entitylist-filter-option-group').appendTo($('.filter-group'));
    $('.pull-right > .btn-entitylist-filter-submit').appendTo($('.filter-group'));
    $('.entitylist-search').appendTo($('#entitylist-filters'));

    $('.filter-group').css({
        "display": "flex",
    })

    $('#entitylist-filters').css({
        "display": "flex",
        "align-items": "center",
        "justify-content": "space-between"
    })

    $('.btn-entitylist-filter-submit').css({
        "align-self": "self-end",
        "margin-left": "30px"
    });

    $('.entitylist-search').css({
        "align-self": "self-end",
        "margin-left": "30px"
    })

    $('.entitylist-search > input').css({
        "border-radius": "10px",
        "width": "228px",
        "height": "40px",
        "color": "#2a2c2e",
        "padding": "10px",
        "gap": "10px",
        "border": "var(--portalThemeColor1) 2px solid",
        "font-size": "15px",
        "margin-right": "-60px",
    });

    $('#entitylist-filters > div.input-group.pull-left.view-search.entitylist-search > input').css({
        "background-color": "transparent !important"
    })

    $('.input-group-btn:last-child>.btn, .input-group-btn:last-child>.btn-group').css({
        "background-color": "transparent",
        "margin-left": -"70px",
        "border": "none",
        "color": "var(--portalBasicTheme1)",
        "font-size": "22px"
    });

    $('#entitylist-filters > div.filter-group > li > ul > li > div > span').css({
        "display": "none"
    });

    $('#dropdown_0').css({
        "background-color": "transparent",
        "border": "1px solid var(--portalThemeColor1)",
        "border-radius": "10px"
    })
});