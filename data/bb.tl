

#Viewer object to add to Julia's display stack:
using Gtk
using Gtk.ShortNames, Gtk.GConstants
#using GtkRange

using Printf
using GR
include("draw_graph.jl")
win = GtkWindow("Production and routing probleme")
global filename
global taille
global b
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
            button_run = GtkButton("Run")
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

#function value_changed(sl)



signal_connect(button_run, "button-press-event") do
    if f !== nothing
        if get_gtk_property(radio1, :active, Bool)==true
            pic_name,t=draw_all_graph(PDI_resolution_heuristique,f)
            global filename=pic_name
            global taille=t
            #b=true
            #signal_handler_block()
            #gtk_range_set_range(sl,1,t)
            #sl.gtk_range_set_value(t)
            #set_gtk_property!(s,:digits,t)
            #set_gtk_property!(image_preview, :file, string(pic_name,"1"))
        elseif get_gtk_property(radio2, :active, Bool)==true
            println("2")
        elseif get_gtk_property(radio3, :active, Bool)==true
            println("3")
        else
            println("erreur")
        end
    end
end

function value_changed(widget)
    i=get_gtk_property(sl,:value_pos,Int64)
    #t= global taille
    #f= global filename
    global taille
    global filename
    if value< taille
        set_gtk_property(image_preview, :file, string( filename,value))
    end
    return i
end
id = signal_connect(value_changed,sl,"value_changed")
#=
 do
    global taille

    println(i)
    #if value<i
    #    set_gtk_property(image_preview, :file, string(filename,value))
    #end
end=#
label = GtkLabel("")
GAccessor.text(label,"")

showall(win)

if !isinteractive()
    @async Gtk.gtk_main()
    Gtk.waitforsignal(win,:destroy)
end
