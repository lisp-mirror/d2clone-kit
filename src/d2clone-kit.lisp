(in-package :d2clone-kit)

(defunl handle-event (event)
  "Broadcasts liballegro event EVENT through ECS systems."
  (let ((event-type
          (cffi:foreign-slot-value event '(:union al:event) 'al::type)))
    (if (eq event-type :display-close)
        (broadcast-quit)
        (broadcast-event event-type event))))

(defunl game-loop (event-queue &key (repl-update-interval 0.3))
  "Runs game loop."
  ;; TODO : init systems DSL style someplace else
  (make-instance 'coordinate-system)
  (make-instance 'debug-system)
  (make-instance 'sprite-batch-system)
  (let ((camera-entity (make-entity)))
    (make-component (make-instance 'camera-system) camera-entity)
    (make-component (system-ref 'coordinate) camera-entity :x 0d0 :y 0d0))
  (let ((map-entity (make-entity)))
    (make-component (make-instance 'map-system) map-entity :prefab 'map)
    (make-component (system-ref 'coordinate) map-entity :x 0d0 :y 0d0))
  (let ((map-entity (make-entity)))
    (print map-entity)
    (make-component (system-ref 'map) map-entity :prefab 'map2)
    (make-component (system-ref 'coordinate) map-entity :x -10d0 :y 0d0))
  (let ((map-entity (make-entity)))
    (make-component (system-ref 'map) map-entity :prefab 'map3)
    (make-component (system-ref 'coordinate) map-entity :x 0d0 :y -10d0))
  (let ((sprite-entity (make-entity)))
    (make-component (make-instance 'sprite-system) sprite-entity :prefab 'heroine)
    (toggle-layer sprite-entity 'head t)
    (toggle-layer sprite-entity 'clothes t)
    (make-component (make-instance 'player-system) sprite-entity)
    (setf (camera-target) sprite-entity)
    (make-component (make-instance 'character-system) sprite-entity :target-x 0d0 :target-y 0d0)
    (make-component (system-ref 'coordinate) sprite-entity :x 0d0 :y 0d0))
  ;; (let ((char-entity (make-entity)))
  ;;   (make-component (system-ref 'sprite) char-entity :prefab 'heroine)
  ;;   (toggle-layer char-entity 'clothes t)  ;; всадник без головы кек
  ;;   (make-component (system-ref 'coordinate) char-entity :x 0d0 :y 0d0)
  ;;   (make-component (make-instance 'character-system) char-entity :target-x 3d0 :target-y 3d0))

  (gc :full t)
  (log-info "Starting game loop")
  (with-system-config-options ((display-vsync display-fps))
    (let* ((vsync display-vsync)
           (builtin-font (al:create-builtin-font))
           (white (al:map-rgb 255 255 255))
           (event (cffi:foreign-alloc '(:union al:event)))
           (renderer (make-renderer))
           (last-tick (al:get-time))
           (last-repl-update last-tick))
      ;; TODO : рестарт для продолжения лупа
      (sleep 0.016)
      (loop do
        (unless (loop while (al:get-next-event event-queue event)
                      always (handle-event event))
          (loop-finish))
        (let ((current-tick (al:get-time)))
          (when (> (- current-tick last-repl-update) repl-update-interval)
            (livesupport:update-repl-link)
            (setf last-repl-update current-tick))
          (with-systems sys
            (system-update sys (- current-tick last-tick)))
          (with-systems sys
            (system-draw sys renderer))
          (al:clear-to-color (al:map-rgb 0 0 0))
          (do-draw renderer)
          (when display-fps
            ;; TODO : smooth FPS counter, like in allegro examples
            (al:draw-text
             builtin-font white 0 0 0
             (format nil "FPS: ~d" (round 1 (- current-tick last-tick)))))
          (setf last-tick current-tick))
        (when vsync
          (setf vsync (al:wait-for-vsync)))
        (al:flip-display))
      (cffi:foreign-free event))))

(defunl start-engine (game-name)
  "Initializes and starts engine using assets specified by GAME-NAME."
  (let ((data-dir
          (merge-pathnames
           (make-pathname :directory `(:relative ,game-name))
           (uiop:xdg-data-home))))
    (ensure-directories-exist data-dir)
    (init-log data-dir)
    (al:set-app-name game-name)
    (al:init)
    (init-fs game-name data-dir)
    (init-config))
  (unless (al:init-image-addon)
    (error "Initializing image addon failed"))
  (al:init-font-addon)
  (unless (al:init-ttf-addon)
    (error "Initializing TTF addon failed"))
  (unless (al:install-audio)
    (error "Intializing audio addon failed"))
  (unless (al:init-acodec-addon)
    (error "Initializing audio codec addon failed"))

  (with-system-config-options
      ((display-windowed display-multisampling display-width display-height))
    (al:set-new-display-flags
     (if display-windowed
         '(:windowed)
         '(:fullscreen)))
    (unless (zerop display-multisampling)
      (al:set-new-display-option :sample-buffers 1 :require)
      (al:set-new-display-option :samples display-multisampling :require))

    (let ((display (al:create-display display-width display-height))
          (event-queue (al:create-event-queue)))
      (when (cffi:null-pointer-p display)
        (error "Initializing display failed"))
      (al:inhibit-screensaver t)
      (al:set-window-title display game-name)
      (al:register-event-source event-queue (al:get-display-event-source display))
      (al:install-keyboard)
      (al:register-event-source event-queue (al:get-keyboard-event-source))
      (al:install-mouse)
      (al:register-event-source event-queue (al:get-mouse-event-source))

      (al:set-new-bitmap-flags '(:video-bitmap))

      (setf *random-state* (make-random-state t))

      (unwind-protect
           (float-features:with-float-traps-masked
               (:invalid :inexact :overflow :underflow)
             (game-loop event-queue))
        (log-info "Shutting engine down")
        (broadcast-quit)
        (al:inhibit-screensaver nil)
        (unregister-all-systems)
        (al:destroy-display display)
        (al:destroy-event-queue event-queue)
        (al:stop-samples)
        (close-config)
        (close-fs)
        (al:uninstall-system)))))


(defun demo ()
  "Runs built-in engine demo."
  ;; TODO : separate thread?
  (with-condition-reporter
      (start-engine "demo")))
