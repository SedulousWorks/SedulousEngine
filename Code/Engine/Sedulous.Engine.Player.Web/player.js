// The web player's calls into the page, linked with --js-library. A library function names what
// it uses (__deps), so the link keeps FS and IDBFS and its minifier renames them consistently,
// which an eval'd string could not survive.
addToLibrary({
  // The user data directory (a game's save, the user's settings) mounted over the browser's
  // IndexedDB, and what the page stored there before loaded into it. Module.userDataLoaded says
  // when; Module.userDataPersistent says the browser kept the mount (a private window that
  // refuses IndexedDB keeps the directory in memory for the page).
  sedulous_mount_user_data__deps: ['$FS', '$IDBFS', '$UTF8ToString'],
  sedulous_mount_user_data: function (path) {
    var dir = UTF8ToString(path);
    Module.userDataLoaded = false;
    try {
      FS.mount(IDBFS, {}, dir);
    } catch (error) {
      console.warn('saves will last this page only: ' + error);
      Module.userDataLoaded = true;
      return;
    }
    FS.syncfs(true, function (error) {
      if (error) {
        console.warn('saves will last this page only: ' + error);
      } else {
        Module.userDataPersistent = true;
      }
      Module.userDataLoaded = true;
    });
  },
  sedulous_user_data_loaded: function () { return Module.userDataLoaded ? 1 : 0; },
  sedulous_user_data_persistent: function () { return Module.userDataPersistent ? 1 : 0; },

  // What changed under the mount, pushed to the page's storage; finishes in the background.
  sedulous_persist_user_data__deps: ['$FS'],
  sedulous_persist_user_data: function () {
    if (Module.userDataPersistent) {
      FS.syncfs(false, function (error) {
        if (error) console.warn('user data was not saved to the browser storage: ' + error);
      });
    }
  }
});
