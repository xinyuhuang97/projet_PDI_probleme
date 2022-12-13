using Gtk
using Gtk.ShortNames, Gtk.GConstants
#using GtkRange

using Printf
using GR
include("draw_graph.jl")
global filename
global taille
global b
global win
win = GtkWindow("Production and routing probleme")

set_gtk_property!(win, :can_focus, false)
    gbox = GtkBox(:h)
        l1box = GtkBox(:v)
            button_savefig = GtkButton("savefig")
                set_gtk_property!(button_savefig,:visible,true)
                set_gtk_property!(button_savefig,:can_focus,true)
                set_gtk_property!(button_savefig,:label,"Save figure")
                #set_gtk_property!(button_savefig,:expand,false)
                #set_gtk_property!(button_savefig,:fill,true)
                #set_gtk_property!(button_savefig,:position,0)
            image_preview = GtkImage("preview")
                set_gtk_property!(image_preview,:visible,true)
                set_gtk_property!(image_preview,:can_focus,false)
                set_gtk_property!(image_preview,:stock,"gtk-missing-image")
                #set_gtk_property!(image_preview,:expand,false)
                #set_gtk_property!(image_preview,:fill,true)
                #set_gtk_property!(image_preview,:position,1)
        push!(l1box, button_savefig)
        push!(l1box, image_preview)
    push!(gbox, l1box)
        l2box = GtkBox(:v)
            radio1 = GtkRadioButton("1")
                set_gtk_property!(radio1,:label,"Résolution Heuristique")
                set_gtk_property!(radio1,:visible,true)
                set_gtk_property!(radio1,:can_focus,true)
                set_gtk_property!(radio1,:receives_default,false)
                #set_gtk_property!(radio1,:action_name,1)
                set_gtk_property!(radio1,:active,true)
                set_gtk_property!(radio1,:draw_indicator,true)
            radio2 = GtkRadioButton("2")
                set_gtk_property!(radio2,:label,"Résolution MTZ")
                set_gtk_property!(radio2,:visible,true)
                set_gtk_property!(radio2,:can_focus,true)
                set_gtk_property!(radio2,:receives_default,false)
                #set_gtk_property!(radio2,:action_name,2)
                set_gtk_property!(radio2,:active,true)
                set_gtk_property!(radio2,:draw_indicator,true)
                set_gtk_property!(radio2,:group,radio1)
            radio3 = GtkRadioButton("3")
                set_gtk_property!(radio3,:label,"Résolution B&C")
                set_gtk_property!(radio3,:visible,true)
                set_gtk_property!(radio3,:can_focus,true)
                set_gtk_property!(radio3,:receives_default,false)
                #set_gtk_property!(radio2,:action_name,2)
                set_gtk_property!(radio3,:active,true)
                set_gtk_property!(radio3,:draw_indicator,true)
                set_gtk_property!(radio3,:group,radio1)
            button_file_chooser = GtkButton("Choose File")
            stop_label = GtkLabel("Stop parameters")
            GAccessor.justify(stop_label,Gtk.GConstants.GtkJustification.GTK_JUSTIFY_LEFT)
            #h1box=GtkBox(:h)
            sb = GtkGrid()
            function sb_entry(label)
                frame = GtkFrame(label)
                entry = GtkEntry()
                #setproperty!(entry, :input_purpose, 2)
                push!(frame, entry)
                return frame
            end
            sb_parameter_gap = sb_entry("Gap value")
            #set_gtk_property!(parameter_gap,:id,"Gap value")
            #set_gtk_property!(sb_parameter_gap,:text,"Gap value")
            sb_parameter_maxtime = sb_entry("Max time(minutes)")
            #set_gtk_property!(sb_parameter_maxtime,:text,"Max time(minutes)")
            sb[1,1]=sb_parameter_gap
            sb[2,1]=sb_parameter_maxtime
            set_gtk_property!(sb[1,1],:value,"None")
            set_gtk_property!(sb[2,1],:value,"None")
            button_run = GtkButton("Run")
            global sl
            sl = Scale(false, 1 ,100, 1)
            push!(l2box, radio1)
            push!(l2box, radio2)
            push!(l2box, radio3)
            push!(l2box, button_file_chooser)
            push!(l2box, stop_label)
            push!(l2box, sb)
            push!(l2box, sl)
            push!(l2box, button_run)


    push!(gbox, l2box)
    #push!(win, sl）
push!(win, gbox)

#push!(win, l1box)
global f=nothing
function scaleset(widget)
    println( Gtk.GAccessor.value(widget) )
    adj = s.adjustment[GtkAdjustment]
    println( adj.value[Float64] )
end

signal_connect(button_file_chooser, "button-press-event") do widget, event
    #dlg = FileChooserDialog("Select folder", Null(), GtkFileChooserAction.SELECT_FOLDER,
    #                      "gtk-cancel", GtkResponseType.CANCEL,
     #                        "gtk-open", GtkResponseType.ACCEPT)
    #if ret == GtkResponseType.ACCEPT
    #  path = Gtk.bytestring(Gtk._.filename(dlg),true)

     # now do something with the path
    #end
    #destroy(dlg)
    global f = open_dialog("")

    #folder, _ = splitdir(f)
end



signal_connect(button_run, "button-press-event") do widget, event
    #gap=get_gtk_property(sb_parameter_gap, :text, String)
    #println(gtk_frame_get_child(sb))
    if f !== nothing
        if get_gtk_property(radio1, :active, Bool)==true
            #global sl
            global win
            #global sl
            #Gtk.destroy(sl)
            #gtk_widget_destroy(sl)
            pic_name,t=draw_all_graph(PDI_resolution_heuristique,f)
            global filename=pic_name
            global taille=t
            global b=true
            println(filename)
            #gtk_scale_new_with_range()
            #set_gtk_property!(sl,upper_stepper_sensitivity,t)
            #gtk_range_set_range()
            #sl.set_range(1,t)
            #sl = Scale(false, 1 ,t, 1)
            #push!(l2box, sl)
            #showall(win)
            #gtk.range_set_range(sl,1,t)
            #set_gtk_property!(s,:digits,t)
            #set_gtk_property!(image_preview, :file, string(pic_name,"1"))
        elseif get_gtk_property(radio2, :active, Bool)==true
            pic_name,t=draw_all_graph(PDI_resolution_exacte,f)
            global filename=pic_name
            global taille=t
            global b=true
            println(filename)
        elseif get_gtk_property(radio3, :active, Bool)==true
            pic_name,t=draw_all_graph(PDI_branch_and_cut,f)
            global filename=pic_name
            global taille=t
            global b=true
            println(filename)
        else
            println("erreur")
        end
    end
end

function value_changed(widget)
    #value=get_gtk_property(sl,:value_pos,Int64)
    #global sl
    a = Gtk.GAccessor.adjustment(sl)
    value = Gtk.get_gtk_property(a,:value,Float64)
    value = round(Int64, value)
    #value=get_gtk_property(sl,:draw_value,Int64)
    #println(get_gtk_property(sl,:value_pos,Int64),get_gtk_property(sl,:digits,Int64))
    global taille
    global filename
    global b

    #println(taille)
    #,sl.get_value_pos())
    if value<=taille && b==true
        println(string(filename,value,".png"))
        set_gtk_property!(image_preview, :file, string(filename,value,".png"))
    end
    #return i
end


signal_connect(value_changed,sl,"value_changed") #do widget, event
    #global taille

    #println(i)
    #if value<i
    #    set_gtk_property(image_preview, :file, string(filename,value,".png"))
    #end
#end
label = GtkLabel("")
GAccessor.text(label,"")

showall(win)

if !isinteractive()
    c=Condition()
    signal_connect(win, :destroy) do widget
        notify(c)
    end
    wait(c)
end
