function updated_settings = Settings_GUI(current_settings)
% v1.0 Simple GUI pane to display/update analysis settings. This will be
% easily extensible as more options are added. 

   %  Create figure, but keep hidden whilst populating
   f = figure('Visible','off','Position',[360,500,400,400]);
 
   defaultBackground = get(0,'defaultUicontrolBackgroundColor');
   set(f,'Color',defaultBackground);
   
   %  Construct the components and read in the current values.
   
   % ALIGN_WINDOW
   hedit1 = uicontrol('Style','edit','String', num2str(current_settings.ALIGN_WINDOW),...
          'Position',[20,350,90,20]);
   uicontrol('Style','text', 'Position',[20 372 90 12],...
        'String','ALIGN_WINDOW');
      
   % MEAN_WINDOW
   hedit2 = uicontrol('Style','edit','String', num2str(current_settings.MEAN_WINDOW),...
          'Position',[180,350,90,20]);
   uicontrol('Style','text', 'Position',[180 372 90 12],...
        'String','MEAN_WINDOW');   
      
   % SD
   hedit3 = uicontrol('Style','edit','String', num2str(current_settings.SD),...
          'Position',[20,300,90,20]);
   uicontrol('Style','text', 'Position',[20 322 90 12],...
        'String','SD');
      
   % BLOCK_SIZE
   hedit4 = uicontrol('Style','edit','String', num2str(current_settings.BLOCK_SIZE),...
          'Position',[180,300,90,20]);  
   uicontrol('Style','text', 'Position',[180 322 90 12],...
        'String','BLOCK_SIZE');
      
   % BLOCK_TRIALS
   hedit5 = uicontrol('Style','edit','String', num2str(current_settings.BLOCK_TRIALS),...
          'Position',[20,250,90,20]);
   uicontrol('Style','text', 'Position',[20 272 90 12],...
        'String','BLOCK_TRIALS');
    
   % PERCENTILE
   hedit6 = uicontrol('Style','edit','String', num2str(current_settings.PERCENTILE),...
          'Position',[180,250,90,20]);
   uicontrol('Style','text', 'Position',[180 272 90 12],...
        'String','PERCENTILE');
      
   % PREY_WOBBLE
   hedit7 = uicontrol('Style','edit','String', num2str(current_settings.PREY_WOBBLE),...
          'Position',[20,200,90,20]);
   uicontrol('Style','text', 'Position',[20 222 90 12],...
        'String','PREY_WOBBLE');
    
   % FWHM
   hedit8 = uicontrol('Style','edit','String', num2str(current_settings.FWHM),...
          'Position',[180,200,90,20]);
   uicontrol('Style','text', 'Position',[180 222 90 12],...
        'String','FWHM');
      
   % CORRELATION MODE
   hpopup_correlation = uicontrol('Style','popupmenu',...
          'String',{'Pearson','Spearman'},...
          'Position',[20,150,150,25],...
          'Callback',{@popup_correlation_Callback});
   
   uicontrol('Style','text', 'Position',[20 177 90 12],...
        'String','Correlation Mode');
    
   switch current_settings.CORR_TYPE.mode; %Initialize current value. 
   case 'Pearson' 
        set(hpopup_correlation, 'Value', 1); 
   case 'Spearman' 
        set(hpopup_correlation, 'Value', 2);
   end
           
      
   % INTERACTION MODE     
   hpopup_interaction = uicontrol('Style','popupmenu',...
          'String',{'Threshold only','Correlation only', 'Threshold + Correlation'},...
          'Position',[180,150,150,25],...
          'Callback',{@popup_interaction_Callback});

   uicontrol('Style','text', 'Position',[180 177 90 12],...
        'String','Interaction Mode');
      
   switch current_settings.INTERACTION_MODE.mode; %Initialize current value. 
   case 'Threshold' 
        set(hpopup_interaction, 'Value', 1); 
   case 'Correlation' 
        set(hpopup_interaction, 'Value', 2);
   case 'Thres_plus_Corr' 
        set(hpopup_interaction, 'Value', 3);
   end
 
   
   
   % DATA INPUT MODE.
   hpopup_datainput = uicontrol('Style','popupmenu',...
          'String',{'Distance:Prey:Bait','Distance:Bait:Prey'},...
          'Position',[20,100,150,25],...
          'Callback',{@popup_datainput_Callback});

   uicontrol('Style','text', 'Position',[20 127 90 12],...
        'String','Data Input Format');
    
   switch current_settings.DATA_FORMAT.mode; %Initialize current value. 
   case 'Dist:Prey:Bait' 
        set(hpopup_datainput, 'Value', 1); 
   case 'Dist:Bait:Prey' 
        set(hpopup_datainput, 'Value', 2);
   end
      
      
      
      
   % ACCEPT/CANCEL BUTTONS
   haccept = uicontrol('Style','pushbutton','String','ACCEPT',...
          'Position',[20,50,70,25],...
          'Callback',{@button_accept_Callback});
   
   hcancel = uicontrol('Style','pushbutton','String','CANCEL',...
          'Position',[100,50,70,25],...
          'Callback',{@button_cancel_Callback});
     
   
   % Assign the GUI a name to appear in the window title.
   set(f,'Name','NanoSPD Parameters', 'numbertitle', 'off')
   % Move the GUI to the center of the screen.
   movegui(f,'center')
        
   % GO GO GO - make the GUI visible.
   set(f,'Visible','on');
   uiwait(f); % Halt the program to allow the user to respond to the GUI.
  
   return; %Return to calling function. 
   
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % CALL BACK FUNCTIONS 
   % Still within function scope, so can still access all data
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   function popup_correlation_Callback(source,eventdata)  
   end

   function popup_interaction_Callback(source,eventdata)
   end

   function popup_datainput_Callback(source,eventdata)
   end


   function button_accept_Callback(source, eventdata)
        % User has potentially changed the values. 
        updated_settings.ALIGN_WINDOW = str2num(get(hedit1,'String'));
        updated_settings.MEAN_WINDOW = str2num(get(hedit2,'String'));
        updated_settings.SD = str2num(get(hedit3,'String'));
        updated_settings.BLOCK_SIZE = str2num(get(hedit4,'String'));
        updated_settings.BLOCK_TRIALS = str2num(get(hedit5,'String'));
        updated_settings.PERCENTILE = str2num(get(hedit6,'String'));
        updated_settings.PREY_WOBBLE = str2num(get(hedit7,'String'));
        updated_settings.FWHM = str2num(get(hedit8,'String'));
        
        % Need to instantiate some unused variable, otherwise wiped from
        % struct upon return to calling function
        updated_settings.CODE_VERSION = current_settings.CODE_VERSION; %Allow user to change this?
        updated_settings.ARCHITECTURE = current_settings.ARCHITECTURE;
        updated_settings.MULTICORE = current_settings.MULTICORE;
        updated_settings.VIEWLINE_RES = current_settings.VIEWLINE_RES;
        updated_settings.VIEWLINE_THICK = current_settings.VIEWLINE_THICK;
        updated_settings.VIEWLINE_SPACING = current_settings.VIEWLINE_SPACING;
       
        
        % UPDATE CORRELATION MODE
        str = get(hpopup_correlation, 'String');
        val = get(hpopup_correlation,'Value');
        
        switch str{val};
        case 'Pearson' 
            updated_settings.CORR_TYPE = Correlation_Type.Pearson
        case 'Spearman' 
            updated_settings.CORR_TYPE = Correlation_Type.Spearman
        end
        
        % UPDATE INTERACTION MODE
        str = get(hpopup_interaction, 'String');
        val = get(hpopup_interaction,'Value');
        
        switch str{val};
        case 'Threshold only' 
            updated_settings.INTERACTION_MODE = Interaction_Mode.Threshold;
        case 'Correlation only' 
            updated_settings.INTERACTION_MODE = Interaction_Mode.Correlation;
        case 'Threshold + Correlation'
            updated_settings.INTERACTION_MODE = Interaction_Mode.Threshold_plus_Correlation;
        end

         % UPDATE DATA_FORMAT
        str = get(hpopup_datainput, 'String')
        val = get(hpopup_datainput, 'Value')
       
        switch str{val};
        case 'Distance:Prey:Bait' 
            updated_settings.DATA_FORMAT = Data_Type.Linescan_D_P_B
        case 'Distance:Bait:Prey' 
            updated_settings.DATA_FORMAT = Data_Type.Linescan_D_B_P
        end

        % All values updated, resume UI and close figure.
        uiresume(f); 
        close(f);
    end

    function button_cancel_Callback(source, eventdata)
        updated_settings = -1; %dont update, return -1 to trigger response
        uiresume(f); %resume flow allowing return to calling function
        close(f); %kill figure
    end
 
 
end 