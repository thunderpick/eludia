	Ext.BLANK_IMAGE_URL = '/i/0.gif';
	Ext.util.Cookies.set ('ExtJs', 1);
	Ext.Ajax.url        = '/';

	var sid			= null;
	var fio			= null;
	var menu_md5	= '';
	var target		= null;

/////////////// CORE

	function nope (url, _target, options) {

		target = _target ? _target : center;

		clear (target);

		Ext.Ajax.request ({

			url: url,

			success: function (response, options) {

				var s = response.responseText;

//				try {

					eval (s);

//				}
//				catch (e) {

//					Ext.MessageBox.alert ('������', '<pre>' + e.description + "\n" + s + '</pre>');

//				}



			}

		});

		target.doLayout ();

	}

/////////////// FORM

	function createFormPanel (options) {
	
		var form_name = options.name;
			
		var formOptions = {
		
			frame:true,
			title: 'Simple Form',
			layout: 'form',
			buttonAlign  : 'center',

			labelWidth: 200,
			labelSeparator: ' ',

			defaults: {width: 230},
			
			autoScroll  : true,
			
			id : form_name,

			listeners : {
			
				afterrender : function (_this) {
				
					var f = _this.getEl ().dom.parentNode;
					
					f.enctype = f.encoding = 'multipart/form-data';					
					f.target  = 'invisible';

				}

			}                    

		};
	
		var form = new Ext.Panel (formOptions);
	
		if (!options.no_ok) {
				
			form.addButton ({text: options.label_ok}, function () {this.getEl ().dom.parentNode.submit ()}, form);
			
		}
		
		if (!options.no_cancel) {
		
			var esc_href = options.esc + '&sid=' + sid;
		
			form.addButton ({text: options.label_cancel}, function () {nope (esc_href, this)}, target);
			
		}
		
		form.add (new Ext.form.Hidden ({name: '__iframe_target', value: 1}));
		
		for (var r = 0; r < options.rows.length; r ++) {
		
			var row = options.rows [r];
			
			var button = row [0];
			
				if (button.type == 'select') {
									
					var values = button.values;
					
					if (button.empty) values.unshift ({id : '', label : button.empty});

					var f = new Ext.form.ComboBox ({

						name  : '__' + button.name,
						hiddenName  : '_' + button.name,

						store: new Ext.data.JsonStore ({
							id: 0,
							fields: ['id', 'label'],
							data: values
						}),

						valueField: 'id',
						fieldLabel: button.label,
						displayField: 'label',
						width: '100%',
						mode: 'local',
						editable: false,
						triggerAction: 'all'

					});

					var max = 0;

					for (var j = 0; j < values.length; j ++) {

						var v = values [j];

						var l = v.label.length;

						if (max < l) max = l;

						if (v.selected) {

							f.setValue (v.id);

							break;

						}

					}

					f.setWidth (10 * max);

					form.add (f);
				
				}				
				else if (button.type == 'checkboxes') {
				
					var node = new Ext.tree.TreeNode ();

					var width = 100;

					for (var i = 0; i < button.values.length; i ++) {
					
						var v = button.values [i];
						
						var l = v.label;
						
						form.add (new Ext.form.Hidden ({name: '_' + button.name + '_' + v.id, value: v.checked}));
												
						var w = 34 + 7 * l.length;

						if (width < w) width = w;
											
						node.appendChild ({

							id: button.name + '_' + v.id,
							text: l,							
							leaf: true,
							iconCls :'no-icon',
							checked: (v.checked == 1)
						
						});
					
					}

					form.add ({
					
						xtype:'treepanel',
						fieldLabel: button.label,
						autoScroll: true,
						animate: true,
						lines: false,
						containerScroll: true,
						border: false,
						rootVisible: false,
						height: button.height ? button.height : 150,
					        margins: '5 0 5 5',
					        width:width,
						root: node,
					
						listeners : {
						
							checkchange : function (node, checked) {

								var div = node.ui.getIconEl ().parentNode;
								
								var name = div.attributes ['ext:tree-node-id'].value;
								
								var q = "*[name='_" + name + "']";

								var hidden = Ext.DomQuery.selectNode (q);

								hidden.value = checked ? 1 : '';

							}
						
						}

					});					
				
				}
		
		}

		for (var k = 0; k < options.keep_params.length; k ++) {
		
			var kp = options.keep_params [k];
		
			form.add (new Ext.form.Hidden ({name: kp.name, value: kp.value}));
		
		}

		return form;
	
	}

/////////////// TABLE

	function adjust_column_widths (columns, data) {

		for (var i = 0; i < columns.length; i ++) {

			var c = columns [i];

			if (c.width > 0) continue;

			c.width = 1;

			for (var j = 0; j < data.length; j ++) {

				var r = data [j];

				var d = r ['f' + i];

				if (d == null || d == '') continue;

				var w = 7 * d.length;

				if (c.width < w) c.width = w;

			}

		}

	}
	
	function createGridToolbar (buttons, store) {
	
		var tb = new Ext.Toolbar ({
			
		});
		
		for (var i = 0; i < buttons.length; i ++) {
		
			var button = buttons [i];
			
			if (button.type == 'input_text') {

				if (button.label) tb.add (button.label + ': ');

				var f = new Ext.form.TextField ({
				
					name  : button.name,
					value : button.value,
					grow  : true,
					width : 30,

					enableKeyEvents : true,

					listeners       : {

						afterRender : function () {

							if (Ext.isIE6 || Ext.isIE7) {
								this.el.setY(1 + this.el.getY());
							}

						},

						keyup : function (_this, _e) {
						
							if (store.baseParams [_this.name] == _this.getValue ()) return;

							store.setBaseParam (_this.name, _this.getValue ());
							
							store.load ({});

						}

					}
				
				});
				
				tb.add (f);
				
			}
			else if (button.type == 'input_date') {





				if (button.label) tb.add (button.label + ': ');

				var f = new Ext.form.DateField ({
				
					name   : button.name,
					format : button.format,
					value  : button.value,
					width  : 80,

					listeners       : {

						afterRender : function () {

							if (Ext.isIE6 || Ext.isIE7) {
								this.el.setY(2 + this.el.getY());
								this.trigger.setY(1 + this.trigger.getY());
							}

						},

						select : function (_this, _e) {
						
							if (store.baseParams [_this.name] == _this.getValue ()) return;

							store.setBaseParam (_this.name, _this.getValue ());
							
							store.load ({});

						}

					}
				
				});

				tb.add (f);








			}
			else if (button.type == 'input_select') {
			
				var values = button.values;


				var f = new Ext.form.ComboBox ({
				
					name  : button.name,

					store: new Ext.data.JsonStore ({
						id: 0,
						fields: ['id', 'label'],
						data: values
					}),
					
					valueField: 'id',
					displayField: 'label',
					mode: 'local',
					editable: false,
					triggerAction: 'all',

					listeners       : {
					
						afterRender : function () {

							if (Ext.isIE6 || Ext.isIE7) {
								this.el.setY(2 + this.el.getY());
								this.trigger.setY(1 + this.trigger.getY());
							}

						},

						select : function (_this, record, index) {

								if (store.baseParams [_this.name] == _this.getValue ()) return;

								store.setBaseParam (_this.name, _this.getValue ());

								store.load ({});

							}

						}
				
					}
					
				);
				
				var max = 0;
				
				for (var j = 0; j < values.length; j ++) {
				
					var v = values [j];
					
					var l = v.label.length;
					
					if (max < l) max = l;
					
					if (v.selected) {
					
						f.setValue (v.id);
						
						break;
					
					}
				
				}
				
				f.setWidth (10 * max);
				
				tb.add (f);

			}
		
		}
		
		return tb;

	};

	function createGridPanel (data, columns, storeOptions, fields, panelOptions, base_params, buttons) {

		adjust_column_widths (columns, data.root);

		storeOptions.fields      = fields;
		storeOptions.root        = 'root';
		storeOptions.autoDestroy = true,
		storeOptions.data        = data;
		storeOptions.url         = '/';
		storeOptions.baseParams  = base_params;

		panelOptions.store    = new Ext.data.JsonStore (storeOptions);
		panelOptions.colModel = new Ext.grid.ColumnModel ({columns: columns});
		panelOptions.sm       = new Ext.grid.RowSelectionModel ({singleSelect:true});
		if (buttons.length > 0)	panelOptions.tbar = createGridToolbar (buttons, panelOptions.store);

		if (data.total) {

			panelOptions.bbar     = new Ext.PagingToolbar ({
				store    : panelOptions.store,
				pageSize : data.cnt
			});

		}

		return new Ext.grid.GridPanel (panelOptions);

	}

/////////////// MENU

	function createSubMenuItem (m) {

		if (m == 'BREAK') return new Ext.menu.Separator ({});

		return new Ext.menu.Item ({

			text    : m.label,
			options : m,
			handler : menuButtonHandler

		});

	}

	var menuButtonHandler = function (b, e) {

		var options = b.options;

		if (options.no_page) return;

		if (options.name) {

			var href = '/?sid=' + sid + '&type=' + b.options.name;

			href += '&_salt=' + Math.random ();

			nope (href);

		}

	}

	function createMenuButton (mi) {

		var b = new Ext.Button ({

			text    : mi.label.replace ("&", ""),
			options : mi,
			handler : menuButtonHandler

		});

		var ii = mi.items;

		if (!ii) return b;

		var sm = new Ext.menu.Menu ({
			plain: true,
			showSeparator  : false
		});

		for (var j = 0; j < ii.length; j ++) sm.add (createSubMenuItem (ii [j]));

		b.menu = sm;

		return b;

	}

	function clear (container) {

		var items = container.items;

		items.each (function (item) {

			this.remove (item);
			item.destroy ();

		}, items);

	}

	function createMenu (tb, m, showFirstPage) {

		clear (tb);

		for (var i = 0; i < m.length; i ++) {

			if (m [i].off) continue;

			var button = createMenuButton (m [i]);

			tb.add (button);

			if (!showFirstPage) continue;

			menuButtonHandler (button, null);

			showFirstPage = false;

		}

		tb.doLayout ();

	}
	
/////////////// MISC

	var applicationExit = function (e) {

		Ext.MessageBox.confirm (

			'���������� ������',

			'�� �������, ��� ������ ��������� ������ � �����������?',

			function (btn) { if (btn == 'yes') window.close () }

		);

	}