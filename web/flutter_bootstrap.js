{{flutter_js}}
{{flutter_build_config}}

const loading = document.createElement('h2');
document.body.appendChild(loading);
loading.textContent = "Loading entrypoint...";

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    loading.textContent = "Initializing engine...";
    const appRunner = await engineInitializer.initializeEngine();

    loading.textContent = "Launching app...";
    await appRunner.runApp();
  }
});
