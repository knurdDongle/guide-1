<template>
  <v-app>
    <toolbar></toolbar>
    <v-content>
      <v-container fluid>
        <router-view></router-view>
      </v-container>
    </v-content>
    <a-footer />
  </v-app>
</template>

<script lang="ts">
import Vue from 'vue'
import Component from 'vue-class-component'
import AFooter from 'client/components/AFooter.vue'

import Toolbar from './components/Toolbar.vue'

@Component({
  components: {
    Toolbar,
    AFooter
  }
})
export default class RootComponent extends Vue {}

</script>

<style>
*,
*:before,
*:after {
  box-sizing: border-box;
}
p {
  margin: 0;
}
code.sourceCode {
  min-width: 100%;
  padding: 8px;
  margin: 0 0 15px;
}
</style>