// -------------------------
//  Task list grid
// -------------------------

// the column model which we want to cache on the browser
var columnModel;

/*
  Sends an ajax request to save the given user preference to the db
*/
/*function saveUserPreference(name, value) {
  var params = { "name": name, "value": value };
  jQuery.post("/users/set_preference",  params);
}
function getUserPreference(name) {
  var url = "/users/get_preference?name=" + name;
  jQuery.post("/users/set_preference",  params);
}

function selectRow(rowid) {
  jQuery('#task_list').setCell(rowid, 'read', 't');
  jQuery('#' + rowid).removeClass('unread');
  loadTask(rowid);
}

function setRowReadStatus(data) {
  for ( var i in data.tasks.rows ) {
    var row = data.tasks.rows[i];
    if (row.read == 'f') {
	    jQuery('#' + row.id).addClass('unread');
    }
  }
}

function taskListConfigSerialise() {
  var model = jQuery("#task_list").jqGrid('getGridParam', 'colModel');

  jQuery.ajax({
    type: "POST",
    url: '/users/set_tasklistcols',
    data: { model : JSON.stringify(model)},
    dataType: 'json',
    success: function(msg) {
      alert( "Data Saved: " + msg );
    }
  });
}

var group_value = ""

function change_group() {
  var vl = jQuery("div.ui-pg-div > #chngroup").val();
  if(vl) {
    group_value = vl;
      jQuery.post("/users/set_task_grouping_preference/" +  vl, function() {
      if(vl == "clear") {
        jQuery("#task_list").jqGrid('groupingRemove',true);
      } else {
        jQuery("#task_list").jqGrid('groupingGroupBy',vl);
      }
    });
  }
}
*/

/* Since the json call is asynchronous
  it is important that this function then calls
  the initGrid to finish loading the grid,
  but only after it has returned successfully
*/
jQuery(document).ready(function() {
  jQuery('div.task_filters>ul>li>a').click(loadFilterPanel);
  jQuery('#tags .panel_content a').click(loadFilterPanel);
  loadTasksNewList();
  

  //override the standard reloadGrid event handler
  //save jggrid scroll position before call reloadGrid event
});

function loadTasksNewList(order) {
  if ((order == "") || (order == undefined)) {
    order = "client";
  }
  jQuery('#task_list_options').empty();
  jQuery('#task_pager').hide();
  displayLoading('#task_list_result');
  jQuery.ajax({
    async: true,
    url: '/tasks?format=json&order=' + order,
    dataType: 'json',
    success:function(response) {
      renderHeader(response.tasks.records, order);
      renderItems(response.tasks.rows, response.tasks.records, order);
      checkResultHeight();
    },
    error:function (xhr, thrownError) {
      alert("Não foi possível recuperar a lista de tarefas");
    }
  });
}

function checkResultHeight() {
  if (parseInt(jQuery('#task_list_result').css('height')) > 200 ) {
    jQuery('#task_list_result').css('height', '200px');
    jQuery('#task_pager').show();
  }
}

function displayLoading(entity) {
  jQuery(entity).html("Carregando resultados... ");
  showLoadingAnimationFor(jQuery(entity));
}

function buildItem(rec) {
  var text = '<tr><td><a href="javascript:loadTask('+ rec.id +');">'+ rec.summary + 
  '</a></td><td>' + rec.id + '</td><td>' + rec.updated_at + '</td><td>';
  if (rec.due != '') {
    text = text + rec.due;
  } else {
    text = text + '&nbsp;';
  }
  text = text + '</td></tr>';
  return text;
}

function renderClient(clientName, items) {
  return '<tr><td colspan="4" class="client">Cliente: ' + clientName + items + "</td></tr>";
}

function renderHeader(resultAmount, currentOrder) {
  jQuery('#task_list_options').html("<p>" + resultAmount + " tarefas encontradas ordenadas por " + 
    decodeOrder(currentOrder) + ". Ordenar por " + otherSortOptions(currentOrder) + '</p>');
}

function renderItems(rows, resultAmount, order) {
  jQuery('#task_list_result').empty();
  if (order == "client") {
    renderItemsByClient(rows, resultAmount);
  } else {
    renderItemsByDefaultOrder(rows, resultAmount);
  }
}

function renderItemsByClient(rows, resultAmount) {
  var text = buildTableHeader();
  if (resultAmount > 0) {
    var clientName = "fhjdlakshf";
    var items = "";
    for (var i = 0; i < resultAmount; i++) {
      var rec = rows[i];
      if ((clientName != "fhjdlakshf") && (clientName != rec.client)) {
        text = text + renderClient(clientName, items);
        items = "";
      }
      items = items + buildItem(rec);
      clientName = rec.client;
    }
    text = text + renderClient(clientName, items);
  }
  jQuery('#task_list_result').append(text + '</table>');  
}

function buildTableHeader() {
  return '<table class="tasklist_table"><tr><th>Nome</th><th>Tarefa</th><th>Movimentada há</th><th>Prazo</th></tr>';
}

function renderItemsByDefaultOrder(rows, resultAmount) {
  var text = buildTableHeader();
  for (var i = 0; i < resultAmount; i++) {
    var rec = rows[i];
    text = text + buildItem(rec);
  }
  jQuery('#task_list_result').append(text + '</table>');
  // jQuery('#task_list_result').append('<table class="tasklist_table"><tr><th>Nome</th><th>Tarefa</th><th></tr>');
  // for (var i = 0; i < resultAmount; i++) {
  //   var rec = rows[i];
  //   jQuery('#task_list_result').append(buildItem(rec));
  // }
  // jQuery('#task_list_result').append('</table>');
}

function decodeOrder(order) {
  switch(order) {
      case 'updated_at':
        return "última movimentação";
      case 'summary':
        return "nome";
      case 'id':
        return "número";
      case 'client':
        return "cliente";
      case 'due':
        return 'prazo';
      default:
        return "cliente";
    }
}

function otherSortOptions(currentOrder)
{
  var text = "";
  var first = true;
  if (currentOrder != 'updated_at') {
    text = text + buildSortOption("data de movimentação", 'updated_at', first);
    first = false;
  }
  if (currentOrder != 'summary') {
    text = text + buildSortOption("nome da atividade", 'summary', first);
    first = false;
  }
  if (currentOrder != 'id') {
    text = text + buildSortOption("número da tarefa", 'id', first);
    first = false;
  }
  if (currentOrder != 'client') {
    text = text + buildSortOption("nome do cliente", 'client', first);
    first = false;
  }
  if (currentOrder != 'due') {
    text = text + buildSortOption("prazo", 'due', first);
    first = false;
  }
  return text
}

function buildSortOption(text, link_to, first) {
  var ret = "";
  if (first == false) {
    ret = ",";
  }
  ret = ret + ' <a href="javascript:loadTasksNewList(\'' + link_to + '\')">' + text + '</a>';
  return ret;
}

function showAllFoundTasks() {
  jQuery('#task_list_result').css('height', 'auto');
  jQuery('#task_pager').hide();
}

/*
function initTaskList() {
  jQuery('#task_list').jqGrid({
        url : '/tasks?format=json',
        datatype: 'json',
        jsonReader: {
          root: "tasks.rows",
          repeatitems:false,
          records: "tasks.records",
          userdata: "tasks.userdata"
        },
        colModel : columnModel.colModel,
        loadonce: false,
        sortable : function(permutation) { taskListConfigSerialise(); }, // re-order columns
        sortname: columnModel.currentSort.column,
        sortorder: columnModel.currentSort.order,

        caption: "Tasks",
        viewrecords: true,
        multiselect: false,

        onSelectRow: function(rowid, status) { selectRow(rowid); },
        onClickGroup: function(hid, collapsed) { saveCollapsedStateToLocalStorage(hid, collapsed) },
        resizeStop: function(newwidth, index) { taskListConfigSerialise(); },
        loadComplete: function(data) { restoreCollapsedState(); jQuery("#load_task_list").hide(); restorejqGridScrollPosition(); setRowReadStatus(data);},
        shrinkToFit: true,

        pager: '#task_pager',
        emptyrecords: 'No tasks found.',
        pgbuttons:false,
        pginput:false,
        recordtext: '{2} tasks found.',

        footerrow: true,
        userDataOnFooter: true,

        height: 300,
        width: 500,

        grouping: jQuery("#chngroup").val() != "clear",
        groupingView: {
           groupField: [jQuery("#chngroup").val()],
           groupColumnShow: [false],
           groupSummary : [true]
        }
  });

  jQuery('#task_list').navGrid('#task_pager', {refresh:true, search:false, add:false, edit:false, view:false, del:false},
        {}, // use default settings for edit
        {}, // use default settings for add
        {}, // use default settings for delete
        {}, // use default settings for search
        {} // use default settings for view
  );

  jQuery("#task_list").jqGrid('sortableRows', {
    update: function(event, ui) {
    if (jQuery("#chngroup").val() != "clear") {
                var id = ui.item.index();
                for (i=id;i>=0;i--) {
                        if (jQuery("tbody.ui-sortable > tr.ui-widget-content").eq(i-1).attr("id").match(/task_listghead/) != null) {
                var group_id = jQuery("tbody.ui-sortable > tr.ui-widget-content").eq(i-1).attr("id");
                        var group_text = jQuery("#" + group_id + " > td").text();
                var group_icon;
                if (group_text == "") {
                        group_icon = jQuery("#" + group_id + " > td > span > img").attr("src");
                }
                        break;
                        }
                }
                var group = getCurrentGroup();
                jQuery.post("/tasks/set_group/"+ ui.item.attr("id") +"?group=" +  group + "&value=" + group_text+ "&icon=" + group_icon);
        if (group_text != "") {
                jQuery('.ui-sortable > tr#'+ ui.item.attr("id") +' > td[aria-describedby=\"task_list_'+ group + '\"]').text(group_text);
                jQuery('.ui-sortable > tr#'+ ui.item.attr("id") +' > td[aria-describedby=\"task_list_'+ group + '\"]').attr('title', group_text);
        } else if(group_icon != undefined) {
                var image = jQuery("#" + group_id + " > td").html();
                jQuery('.ui-sortable > tr#'+ ui.item.attr("id") +' > td[aria-describedby=\"task_list_'+ group + '\"]').html(image);
                jQuery('.ui-sortable > tr#'+ ui.item.attr("id") +' > td[aria-describedby=\"task_list_'+ group + '\"] > span.ui-icon').remove();
        }
        }
    }
  });

  jQuery("#task_list").jqGrid('gridResize', {
        stop: function(event, ui) {
                resizeGrid(); // force width
    },
    minHeight: 150,
    maxHeight: 1000
  });

  jQuery("#task_list").jqGrid('navButtonAdd','#task_pager', {
    caption: "Columns",
    title: "Show/hide columns",
    onClickButton : function () {
      jQuery("#task_list").jqGrid('columnChooser', {
        done: function (id) { taskListConfigSerialise(); }
      });
    }
  });

  jQuery("#task_list").jqGrid('navButtonAdd','#task_pager', {
        caption: "Export",
        title: "Export data to CSV",
        onClickButton : function () {
      window.location.href="/tasks/get_csv";
        }
  });

  jQuery("#task_list").jqGrid('navButtonAdd','#task_pager', {
      caption: jQuery("#groupby").html(),
      buttonicon: "none",
      id: "jgrid_footer_changegroup"
  });
  jQuery('#task_pager_center').remove();
  resizeGrid();
}

jQuery.extend(jQuery.fn.fmatter , {
  tasktime : function(cellvalue, options, rowdata) {
    var val = timeTaskValue(cellvalue);
    return val;
  }
});

jQuery.extend(jQuery.fn.fmatter , {
  read : function(cellvalue, options, rowdata) {
		return "<span class='unread_icon'/>";
  }
});


jQuery(window).bind('resize', function() {
  resizeGrid();
});

function resizeGrid() {
  jQuery("#task_list").setGridWidth(jQuery(".span10").width()); //allow for sidebar and margins
}

function timeTaskValue(cellvalue) {
        if (cellvalue == 0) {
          return "";
        }
        return Math.round(cellvalue/6)/10 + "hr";
}
*/
function tasksViewReload()
{
    loadTasksNewList();
    jQuery('#calendar').fullCalendar('refetchEvents');
}

function ajax_update_task_callback() {
  jQuery('#taskform').bind("ajax:success", function(event, json, xhr) {
    authorize_ajax_form_callback(json);
    var task = json;
    jQuery('#errorExplanation').remove();
    jQuery("span.fieldWithErrors").removeClass("fieldWithErrors");
    if (task.status == "error") {
      var html = "<div class='errorExplanation' id='errorExplanation'>";
      html += "<h2>"+ task.messages.length +" error prohibited this template from being saved</h2><p>There were problems with the following fields:</p>";
      for (i=0 ; i < task.messages.length ; i++) {html += "<ul><li>"+ task.messages[i] + "</li></ul>";}
      html += "</div>"
      jQuery(html).insertAfter("#task_id");
    }
    else {
      if (jQuery("#task_list").length) {jQuery("#task_list").trigger("reloadGrid");}
      //update tags
      jQuery("#tags").replaceWith(html_decode(task.tags));
      loadTask(task.tasknum);
      flash_message(task.message);
    }
  }).bind("ajax:before", function(event, json, xhr) {
    if (jQuery("#task_list").length) {
      savejqGridScrollPosition();
    }
    showProgress();
  }).bind("ajax:complete", function(event, json, xhr) {
    hideProgress();
  }).bind("ajax:failure", function(event, json, xhr, error) {
    alert('error: ' + error);
  });
}
/*
function restoreCollapsedState() {
  if (typeof(localStorage) != 'undefined' && getCurrentGroup() != 'clear') {
    for (var i = 0; i < localStorage.length; i++){
      var regex = new RegExp("gridgroup_" + getCurrentGroup() + "_task_listghead_[0-9]+","g");
      if (regex.test(localStorage.key(i)) && localStorage.getItem(localStorage.key(i)) == 'h') {
        var hid = "task_listghead_" + localStorage.key(i).split('_')[4];
        if (jQuery("#" + hid).length) {
          jQuery("#task_list").jqGrid('groupingToggle', hid);
        }
      }
    }
  }
}

function saveCollapsedStateToLocalStorage(hid, collapsed) {
  if (typeof(localStorage) != 'undefined') {
    if (collapsed) {
      localStorage.setItem("gridgroup_" + getCurrentGroup() + "_" + hid, 'h');
    }
    else {
      localStorage.removeItem("gridgroup_" + getCurrentGroup() + "_" + hid);
    }
  }
}

function getCurrentGroup() {
  if (group_value != "") {
    return group_value;
  } else {
    return jQuery("#chngroup").val();
  }
}

function restorejqGridScrollPosition() {
  if (isLocalStorageExist('jqgrid_scroll_position')) {
    jQuery("div.ui-jqgrid-bdiv").scrollTop(getLocalStorage('jqgrid_scroll_position'));
  }
}

function savejqGridScrollPosition() {
  setLocalStorage("jqgrid_scroll_position", jQuery('div.ui-jqgrid-bdiv').scrollTop());
}
*/